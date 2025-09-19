#!/bin/sh

# install fonttools:
#  pipx install fonttools

for font in SourceHanSansCN-Bold SourceHanSansCN-Normal; do
	fonttools subset --text-file=subset.txt --name-IDs='*' --name-legacy --name-languages='*' --legacy-cmap --symbol-cmap --no-prune-unicode-ranges --no-prune-codepage-ranges $font.otf || exit 1
	[ -s $font.subset.otf ] || exit 1
	cat $font.subset.otf > ../files/assets/$font.otf
	rm -f $font.subset.otf
done
