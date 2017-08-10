#!/bin/bash -eux

AUTHOR="Maximilian Blochberger"
AUTHOR_URL="https://github.com/blochberger"
GITHUB_URL="https://github.com/blochberger/QRCodeReader"
MODULE="QRCodeReader"
README="README.md"
VERSION=$(git describe --always)
LAST_COMMIT=$(git log -1 --format='%H')
GITHUB_FILE_PREFIX="${GITHUB_URL}/blob/${LAST_COMMIT}"
OUTPUT_DIR="gh-pages"

JAZZY="jazzy"
JAZZY_THEME="fullwidth"

COMMIT=false

# Parse command line arguments
while [[ $# -gt 0 ]]; do
	key="$1"

	case $key in
		--commit)
			COMMIT=true
			shift
			;;
		-h|--help)
			echo "Usage: [--commit] [-h|--help]" >&2
			exit 0
			;;
		*)
			echo "Usage: [--commit] [-h|--help]" >&2
			echo "Unknown option: ${key}" >&2
			exit 1
			;;
	esac
done

# Generate documentation
SDK=iphone

for MIN_ACL in public private internal; do
	OUTPUT="${OUTPUT_DIR}/${SDK}/${MIN_ACL}"

	${JAZZY}\
		--clean\
		--use-safe-filenames\
		--theme="${JAZZY_THEME}"\
		--author="${AUTHOR}"\
		--author_url="${AUTHOR_URL}"\
		--github_url="${GITHUB_URL}"\
		--github-file-prefix="${GITHUB_FILE_PREFIX}"\
		--readme="${README}"\
		--module="${MODULE}"\
		--module-version="${VERSION}"\
		--sdk="${SDK}"\
		--min-acl="${MIN_ACL}"\
		--output="${OUTPUT}"
done # MIN_ACL

# Commit results
if [ ${COMMIT} = true ]; then
	(
		cd "${OUTPUT_DIR}"
		git add ${SDK}
		git commit -m "Update documentation to ${VERSION}"
	)
fi

# Cleanup
rm -rf build
