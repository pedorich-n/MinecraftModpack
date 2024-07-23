import sys
import argparse
import logging
import re
from dataclasses import dataclass
from pathlib import Path
from typing import Optional

import tomli
import tomli_w

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

# endregion

# region: Tools
def canonicalize_path(path: Path) -> Path:
    return path.expanduser().resolve()
# endregion

# region: TOML
def read_pack(path: Path) -> PackInfo:
    with open(path, "rb") as pack_file:
        logger.info(f"Reading pack file {path}...")
        return tomllib.load(pack_file)

def write_pack(path: Path, pack: PackInfo) -> None:
    logger.info(f"Writing pack file {path}...")
    with open(path, "wb") as pack_file:
        tomli_w.dump(pack, pack_file)


# endregion


def increment_tag(current_tag, commit_msg):
    # Commit regex: `<type>[optional scope]: <description>`
    pattern = re.compile(r'(\w+)(?:\((.*?)\))?: (.+)')

    next_tag = None
    potential_tag = current_tag.split(".")

    match = pattern.search(commit_msg)
    if match:
        type_value = match.group(1)
        scope_value = match.group(2)
        description_value = match.group(3)

        # TODO: Use regexp, or better yet, replace this function with a smart versioning library
        if "release" in [type_value, scope_value] or scope_value == "major":
            major_version = int(potential_tag[0])
            next_tag = str(major_version+1)+".0.0"
        elif "feat" in type_value:
            feature_version = int(potential_tag[1])
            next_tag = potential_tag[0]+"."+str(feature_version+1)+".0"
        else:
            patch_version = int(potential_tag[2]) + 1
            next_tag = ".".join([potential_tag[0], potential_tag[1], str(patch_version)])

    return next_tag

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--manifest", type=str, required=True, help="Path to a manifest file (usually pack.toml)")
    parser.add_argument("--tag", type=str, required=True, default=None, help="Give current version tag to optionally return incremented version")
    parser.add_argument("--commit-msg", type=str, required=True, default=None, help="Last commit message is needed to create proper versioning")

    args = parser.parse_args()
    pack_path = canonicalize_path(Path(args.manifest))

    with open(pack_path, "rb") as pack_file:
        pack_info = tomli.load(pack_file)
        current_tag = args.tag
        commit_msg = args.commit_msg

        new_tag = increment_tag(current_tag, commit_msg)
    
    if new_tag is None:
        logger.error(f"Failed to deduce proper versioning from commit message: '{commit_msg}'")
        sys.exit(1)

    pack_info["version"] = new_tag
    
    write_pack(pack_path, pack_info)
    
    return new_tag
