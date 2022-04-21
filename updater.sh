#!/bin/bash

rm -f message

latest_version=$(rsync --list-only rsync://rsync.kde.org/kdeftp/stable/release-service/ | awk '{print $5}' | sort -r | sed -n '1p')
last_version=$(cat LATEST)

echo -e "\e[32mLATEST VERSION\e[0m: ${latest_version}" >> message
echo -e "\e[33mLAST VERSION\e[0m: ${last_version}" >> message

if [[ ${latest_version} = ${last_version} ]]; then
    echo -e "\e[34m ==========>\e[0m Package is up-to-date." >> message
    echo -e "\e[34m ==========>\e[0m Nothing to do today." >> message
    exit
fi

# 生成SHA256SUM
curl https://download.kde.org/stable/release-service/${latest_version}/src/dolphin-${latest_version}.tar.xz -LOC -
sha256sum=$(sha256sum dolphin-${latest_version}.tar.xz | awk -F'  ' '{print $1}')

# 更新缓存版本号
echo ${latest_version} > LATEST
git add LATEST
git config --local user.email "41898282+github-actions[bot]@users.noreply.github.com"
git config --local user.name "github-actions[bot]"
git commit -m "New Version ${latest_version}"
git push "https://${GITHUB_TOKEN}@${REPO}" main:main

# 编辑templete
sed "s/%%pkgver%%/${latest_version}/g" PKGBUILD.templete -i
sed "s/%%sha256sum%%/${sha256sum}/g" PKGBUILD.templete -i

sed "s/%%pkgver%%/${latest_version}/g" SRCINFO.templete -i
sed "s/%%sha256sum%%/${sha256sum}/g" SRCINFO.templete -i

# 更新AUR
cd workdir
git clone aur@aur.archlinux.org:trilium-bin-cn.git && cd trilium-bin-cn
cp -f ../../PKGBUILD.templete ./PKGBUILD
cp -f ../../SRCINFO.templete ./.SRCINFO
git add PKGBUILD .SRCINFO
git config user.name ${AUR_NAME}
git config user.email ${AUR_EMAIL}
git commit -m "Update ${latest_version}"
git push -u origin master

cd ../..
echo -e "\e[32m ==========>\e[0m Package has been updated." >> message
rm -rf workdir

