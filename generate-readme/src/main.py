import argparse
import logging
import re
import tomllib
from dataclasses import dataclass
from pathlib import Path
from typing import List, Optional

import dacite
import modrinth
from mdutils.mdutils import MarkDownFile, MdUtils, TextUtils

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
    fabric: str
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
class ModUpdateInfo:
    modrinth: Optional[ModModrinthUpdateInfo]


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
    fabric: str
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
        if isinstance(v, str):
            empty[func(k)] = v
    return empty


def resolve_path(root: Path, input: str) -> Path:
    path = Path(input)
    if not path.is_absolute():
        return root.joinpath(path).resolve()
    else:
        return path


# endregion


# region: TOML
def read_pack(path: Path, dacite_config: dacite.Config) -> PackInfo:
    with open(path, "rb") as pack_file:
        logger.info("Reading pack file...")
        pack_raw = tomllib.load(pack_file)
        pack = dacite.from_dict(
            data_class=PackInfo,
            data=pack_raw,
            config=dacite_config,
        )
        return pack


def read_index(path: Path, dacite_config: dacite.Config) -> IndexInfo:
    with open(path, "rb") as index_file:
        logger.info("Reading index file...")
        index_raw = tomllib.load(index_file)
        index = dacite.from_dict(data_class=IndexInfo, data=index_raw, config=dacite_config)
        return index


def read_mod(path: Path) -> ModInfo:
    with open(path, "rb") as mod_file:
        logger.info("Reading mod file...")
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

    result.description = mod.desc
    result.version = version.versionNumber
    result.url = f"https://modrinth.com/mod/{mod.slug}"

    return result


def get_mod_info_result(mod_info: ModInfo) -> ModInfoResult:
    result = ModInfoResult(name=mod_info.name, side=mod_info.side)

    if mod_info.update.modrinth:
        logger.info(f"Fetching info from Modrinth for {mod_info.name}...")
        result = get_modrinth_mod_info(result, mod_info.update.modrinth)

    return result


def get_pack_info_result(pack_info: PackInfo, mods: List[ModInfo]) -> PackInfoResult:
    result_mods = [get_mod_info_result(mod) for mod in mods]
    result = PackInfoResult(
        name=pack_info.name,
        version=pack_info.version,
        mods=result_mods,
        versions=PackVersionsInfoResult(fabric=pack_info.versions.fabric, minecraft=pack_info.versions.minecraft),
    )

    return result


def generate_readme(info: PackInfoResult):
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

    md_file = MdUtils(file_name="README.md", title="Modpack Info")
    text_utils = TextUtils()

    md_file.new_line("")
    md_file.new_line(text_utils.bold("Name") + f": {info.name}")
    md_file.new_line(text_utils.bold("Version") + f": {info.version}")
    md_file.new_line(text_utils.bold("Minecraft Version") + f": {info.versions.minecraft}")
    md_file.new_line(text_utils.bold("Fabric Version") + f": {info.versions.fabric}")
    md_file.new_line("")

    md_file.new_header(level=1, title="Mods")
    md_list = [format_mod(mod, text_utils) for mod in info.mods]
    md_file.new_list(md_list, marked_with="-")

    md_file.create_md_file()


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--root", type=str, required=True)

    args = parser.parse_args()
    root = Path(args.root).resolve()

    dacite_config = dacite.Config(type_hooks={Path: lambda p: resolve_path(root, p)})
    pack_path = root.joinpath("pack.toml")

    pack_info = read_pack(pack_path, dacite_config)
    index_info = read_index(pack_info.index.file, dacite_config)
    mods_info = [read_mod(file_info.file) for file_info in index_info.files]

    result = get_pack_info_result(pack_info, mods_info)

    generate_readme(result)
