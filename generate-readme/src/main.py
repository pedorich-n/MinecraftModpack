import argparse
import logging
import re
import tomllib
from dataclasses import dataclass
from pathlib import Path
from typing import List, Optional

import dacite
import modrinth
from mdutils.mdutils import MdUtils
from mdutils.tools import TextUtils
from curseforge import CurseClient


logging.addLevelName(logging.WARNING, "WARN")
logging.basicConfig(
    level=logging.INFO,
    format="[{asctime}] [{levelname:<4s}] - {message}",
    datefmt="%Y-%m-%dT%H:%M:%S%z",
    style="{",
)
logger = logging.getLogger(__name__)


# region: Dataclasses
@dataclass
class PackIndexInfo:
    file: Path


@dataclass
class PackVersionsInfo:
    fabric: Optional[str]
    forge: Optional[str]
    minecraft: str


@dataclass
class PackInfo:
    name: str
    version: str
    index: PackIndexInfo
    versions: PackVersionsInfo


@dataclass
class IndexFileInfo:
    file: Path


@dataclass
class IndexInfo:
    files: List[IndexFileInfo]


@dataclass
class ModModrinthUpdateInfo:
    mod_id: str
    version: str


@dataclass
class ModCurseForgeUpdateInfo:
    file_id: int
    project_id: int


@dataclass
class ModUpdateInfo:
    modrinth: Optional[ModModrinthUpdateInfo]
    curseforge: Optional[ModCurseForgeUpdateInfo]


@dataclass
class ModInfo:
    name: str
    side: str
    update: ModUpdateInfo


@dataclass
class ModInfoResult:
    name: str
    side: str
    version: Optional[str] = None
    description: Optional[str] = None
    url: Optional[str] = None


@dataclass
class PackVersionsInfoResult:
    fabric: Optional[str]
    forge: Optional[str]
    minecraft: str


@dataclass
class PackInfoResult:
    name: str
    version: str
    mods: List[ModInfoResult]
    versions: PackVersionsInfoResult


# endregion


# region: Tools
def kebab_to_snake(name: str) -> str:
    snake_case_str = re.sub(r"-", "_", name)
    return snake_case_str


# From https://stackoverflow.com/a/63754024/5408933
def alter_keys(dictionary, func):
    empty = {}
    for k, v in dictionary.items():
        if isinstance(v, dict):
            empty[func(k)] = alter_keys(v, func)
        else:
            empty[func(k)] = v
    return empty


def canonicalize_path(path: Path) -> Path:
    return path.expanduser().resolve()


def resolve_path(root: Path, input: str) -> Path:
    path = Path(input)
    if not path.is_absolute():
        return canonicalize_path(root.joinpath(path))
    else:
        return path


def clean_text(input: str) -> str:
    cleaned_text = re.sub(r"\n+", " ", input)
    cleaned_text = re.sub(r" +", " ", cleaned_text)
    cleaned_text = cleaned_text.strip()

    return cleaned_text


# endregion


# region: TOML
def read_pack(path: Path, dacite_config: dacite.Config) -> PackInfo:
    with open(path, "rb") as pack_file:
        logger.info(f"Reading pack file {path}...")
        pack_raw = tomllib.load(pack_file)
        pack = dacite.from_dict(
            data_class=PackInfo,
            data=pack_raw,
            config=dacite_config,
        )
        return pack


def read_index(path: Path, dacite_config: dacite.Config) -> IndexInfo:
    with open(path, "rb") as index_file:
        logger.info(f"Reading index file {path}...")
        index_raw = tomllib.load(index_file)
        index = dacite.from_dict(data_class=IndexInfo, data=index_raw, config=dacite_config)
        return index


def read_mod(path: Path) -> ModInfo:
    with open(path, "rb") as mod_file:
        logger.info(f"Reading mod file {path}...")
        mod_raw = alter_keys(tomllib.load(mod_file), kebab_to_snake)
        mod = dacite.from_dict(
            data_class=ModInfo,
            data=mod_raw,
        )
        return mod


# endregion


def get_modrinth_mod_info(result: ModInfoResult, update_info: ModModrinthUpdateInfo) -> ModInfoResult:
    mod = modrinth.Projects.ModrinthProject(update_info.mod_id)
    version = modrinth.Versions.ModrinthVersion(mod, update_info.version)

    result.description = clean_text(mod.desc)
    result.version = version.versionNumber
    result.url = f"https://modrinth.com/mod/{mod.slug}"

    return result


def get_curseforge_mod_info(
    result: ModInfoResult, update_info: ModCurseForgeUpdateInfo, client: CurseClient
) -> ModInfoResult:
    mod = client.fetch(f"mods/{update_info.project_id}")

    result.description = clean_text(mod.get("summary"))
    result.url = mod["links"].get("websiteUrl")
    result.version = None  # There's no mod version field in the API :(

    return result


def get_mod_info_result(mod_info: ModInfo, cf_client: Optional[CurseClient]) -> ModInfoResult:
    result = ModInfoResult(name=mod_info.name, side=mod_info.side)

    if mod_info.update.modrinth:
        logger.info(f"Fetching info from Modrinth for {mod_info.name}...")
        result = get_modrinth_mod_info(result, mod_info.update.modrinth)

    elif mod_info.update.curseforge and cf_client:
        logger.info(f"Fetching info from CurseForge for {mod_info.name}...")
        result = get_curseforge_mod_info(result, mod_info.update.curseforge, cf_client)

    return result


def get_pack_info_result(pack_info: PackInfo, mods: List[ModInfo], cf_client: Optional[CurseClient]) -> PackInfoResult:
    result_mods = [get_mod_info_result(mod, cf_client) for mod in mods]
    result = PackInfoResult(
        name=pack_info.name,
        version=pack_info.version,
        mods=result_mods,
        versions=PackVersionsInfoResult(
            fabric=pack_info.versions.fabric,
            forge=pack_info.versions.forge,
            minecraft=pack_info.versions.minecraft,
        ),
    )

    return result


def generate_readme(info: PackInfoResult, output: Path):
    def format_mod(mod: ModInfoResult, text_utils: TextUtils) -> str:
        buffer = []
        if mod.url:
            buffer.append(text_utils.text_external_link(text=text_utils.bold(mod.name), link=mod.url))
        else:
            buffer.append(text_utils.bold(mod.name))
        buffer.append(f" ({mod.side}")
        if mod.version:
            buffer.append(f", {mod.version}")
        buffer.append(")")
        if mod.description:
            buffer.append(f" - {mod.description}")

        return "".join(buffer)

    # This abuses the fact that internally `file_name` is passed into `open`,
    # so it can actually be a full path, not just a filename
    md_file = MdUtils(file_name=output.as_posix(), title="Modpack Info")
    text_utils = TextUtils()

    md_file.new_line("")
    md_file.new_line(text_utils.bold("Name") + f": {info.name}")
    md_file.new_line(text_utils.bold("Version") + f": {info.version}")
    md_file.new_line(text_utils.bold("Minecraft Version") + f": {info.versions.minecraft}")
    if info.versions.fabric:
        md_file.new_line(text_utils.bold("Fabric Version") + f": {info.versions.fabric}")
    if info.versions.forge:
        md_file.new_line(text_utils.bold("Forge Version") + f": {info.versions.forge}")
    md_file.new_line("")

    md_file.new_header(level=1, title="Mods")
    md_list = [format_mod(mod, text_utils) for mod in info.mods]
    md_file.new_list(md_list, marked_with="-")

    md_file.create_md_file()


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--manifest", type=str, required=True, help="Path to a manifest file (usually pack.toml)")
    parser.add_argument("--output", type=str, required=False, default="README.md", help="Path to the output MD file")
    parser.add_argument("--cf-key", type=str, required=False, default=None, help="CurseForge API Key")

    args = parser.parse_args()
    pack_path = canonicalize_path(Path(args.manifest))
    output_path = canonicalize_path(Path(args.output))

    if args.cf_key:
        cf_client = CurseClient(args.cf_key)
    else:
        cf_client = None

    root = pack_path.parent
    dacite_config = dacite.Config(type_hooks={Path: lambda p: resolve_path(root, p)})

    pack_info = read_pack(pack_path, dacite_config)
    index_info = read_index(pack_info.index.file, dacite_config)
    mods = [file for file in index_info.files if "mods" in file.file.parts]
    mods_info = [read_mod(file_info.file) for file_info in mods]

    result = get_pack_info_result(pack_info, mods_info, cf_client)
    generate_readme(result, output_path)
