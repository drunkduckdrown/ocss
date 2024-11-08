#!/bin/bash

# GitHub仓库信息
GITHUB_REPO="Master08s/ocss"
GITHUB_SCRIPT_URL="https://cdn.jsdelivr.net/gh/$GITHUB_REPO@latest/main.sh"
GITHUB_VERSION_URL="https://cdn.jsdelivr.net/gh/$GITHUB_REPO@latest/version.txt"

# 本地脚本路径
LOCAL_SCRIPT_PATH="$(pwd)/ocss.sh"
# 本地版本号路径
LOCAL_VERSION_PATH="$(pwd)/version.txt"

# 检测系统类型
detect_system() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$ID
        VERSION=$VERSION_ID
    elif [ -f /etc/lsb-release ]; then
        . /etc/lsb-release
        OS=$DISTRIB_ID
        VERSION=$DISTRIB_RELEASE
    elif [ -f /etc/debian_version ]; then
        OS="debian"
        VERSION=$(cat /etc/debian_version)
    elif [ -f /etc/redhat-release ]; then
        OS=$(awk '{print $1}' /etc/redhat-release | tr '[:upper:]' '[:lower:]')
        VERSION=$(awk '{print $4}' /etc/redhat-release)
    elif [ -f /etc/arch-release ]; then
        OS="arch"
        VERSION="rolling"
    elif [ -f /etc/alpine-release ]; then
        OS="alpine"
        VERSION=$(cat /etc/alpine-release)
    elif [ -f /etc/SuSE-release ]; then
        OS="suse"
        VERSION=$(grep 'VERSION =' /etc/SuSE-release | awk '{print $3}')
    elif [ -f /etc/gentoo-release ]; then
        OS="gentoo"
        VERSION=$(cat /etc/gentoo-release | awk '{print $5}')
    elif [ -f /etc/slackware-version ]; then
        OS="slackware"
        VERSION=$(cat /etc/slackware-version | awk '{print $2}')
    elif [ -f /etc/mandriva-release ]; then
        OS="mandriva"
        VERSION=$(cat /etc/mandriva-release | awk '{print $3}')
    elif [ -f /etc/mageia-release ]; then
        OS="mageia"
        VERSION=$(cat /etc/mageia-release | awk '{print $3}')
    else
        echo -e "\033[1;31m无法检测系统类型。\033[0m"
        exit 1
    fi
}

# 显示当前系统版本
show_system_info() {
    echo -e "\033[1;32m当前系统: $OS $VERSION\033[0m"
}

# 首次运行时更新软件包列表并安装wget和curl
first_run() {
    if [ ! -f /tmp/first_run_done ]; then
        echo -e "\033[1;33m首次运行，正在更新软件包列表并安装wget和curl...\033[0m"
        if [ "$OS" == "ubuntu" ] || [ "$OS" == "debian" ] || [ "$OS" == "kali" ] || [ "$OS" == "linuxmint" ] || [ "$OS" == "deepin" ] || [ "$OS" == "zorin" ] || [ "$OS" == "armbian" ] || [ "$OS" == "proxmox" ]; then
            sudo apt-get update -y
            sudo apt-get install -y wget curl
        elif [ "$OS" == "centos" ] || [ "$OS" == "rhel" ] || [ "$OS" == "fedora" ] || [ "$OS" == "rocky" ] || [ "$OS" == "almalinux" ] || [ "$OS" == "opencloudos" ] || [ "$OS" == "openeuler" ] || [ "$OS" == "anolis" ]; then
            sudo yum update -y
            sudo yum install -y wget curl
        else
            echo -e "\033[1;31m不支持的系统类型。\033[0m"
            exit 1
        fi
        touch /tmp/first_run_done
        echo -e "\033[1;32m首次运行完成。\033[0m"
    fi
}

# 定义换源函数
change_source() {
    echo -e "\033[1;34m正在更换为$1源...\033[0m"
    if [ "$OS" == "ubuntu" ] || [ "$OS" == "debian" ] || [ "$OS" == "kali" ] || [ "$OS" == "linuxmint" ] || [ "$OS" == "deepin" ] || [ "$OS" == "zorin" ] || [ "$OS" == "armbian" ] || [ "$OS" == "proxmox" ]; then
        sudo cp /etc/apt/sources.list /etc/apt/sources.list.bak
        sudo tee /etc/apt/sources.list <<EOF
# $1源
$2
EOF
        sudo apt-get update
    elif [ "$OS" == "centos" ] || [ "$OS" == "rhel" ] || [ "$OS" == "rocky" ] || [ "$OS" == "almalinux" ] || [ "$OS" == "opencloudos" ] || [ "$OS" == "openeuler" ] || [ "$OS" == "anolis" ]; then
        sudo cp /etc/yum.repos.d/CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo.bak
        sudo tee /etc/yum.repos.d/CentOS-Base.repo <<EOF
# $1源
$2
EOF
        sudo yum makecache
    elif [ "$OS" == "fedora" ]; then
        sudo cp /etc/yum.repos.d/fedora.repo /etc/yum.repos.d/fedora.repo.bak
        sudo tee /etc/yum.repos.d/fedora.repo <<EOF
# $1源
$2
EOF
        sudo yum makecache
    fi
    echo -e "\033[1;32m源已更换为$1源，并已更新软件包列表。\033[0m"
    update_and_clean
}

# 定义恢复官方源函数
restore_official_source() {
    echo -e "\033[1;34m正在恢复为官方源...\033[0m"
    if [ "$OS" == "ubuntu" ] || [ "$OS" == "debian" ] || [ "$OS" == "kali" ] || [ "$OS" == "linuxmint" ] || [ "$OS" == "deepin" ] || [ "$OS" == "zorin" ] || [ "$OS" == "armbian" ] || [ "$OS" == "proxmox" ]; then
        sudo cp /etc/apt/sources.list.bak /etc/apt/sources.list
        sudo apt-get update
    elif [ "$OS" == "centos" ] || [ "$OS" == "rhel" ] || [ "$OS" == "rocky" ] || [ "$OS" == "almalinux" ] || [ "$OS" == "opencloudos" ] || [ "$OS" == "openeuler" ] || [ "$OS" == "anolis" ]; then
        sudo cp /etc/yum.repos.d/CentOS-Base.repo.bak /etc/yum.repos.d/CentOS-Base.repo
        sudo yum makecache
    elif [ "$OS" == "fedora" ]; then
        sudo cp /etc/yum.repos.d/fedora.repo.bak /etc/yum.repos.d/fedora.repo
        sudo yum makecache
    fi
    echo -e "\033[1;32m已恢复为官方源，并已更新软件包列表。\033[0m"
    update_and_clean
}

# 更新软件包、清理缓存并修复依赖
update_and_clean() {
    echo -e "\033[1;33m正在更新软件包...\033[0m"
    if [ "$OS" == "ubuntu" ] || [ "$OS" == "debian" ] || [ "$OS" == "kali" ] || [ "$OS" == "linuxmint" ] || [ "$OS" == "deepin" ] || [ "$OS" == "zorin" ] || [ "$OS" == "armbian" ] || [ "$OS" == "proxmox" ]; then
        sudo apt-get upgrade -y
        echo -e "\033[1;33m正在清理缓存...\033[0m"
        sudo apt-get autoclean
        sudo apt-get autoremove -y
        echo -e "\033[1;33m正在修复依赖...\033[0m"
        sudo apt-get install -f
    elif [ "$OS" == "centos" ] || [ "$OS" == "rhel" ] || [ "$OS" == "fedora" ] || [ "$OS" == "rocky" ] || [ "$OS" == "almalinux" ] || [ "$OS" == "opencloudos" ] || [ "$OS" == "openeuler" ] || [ "$OS" == "anolis" ]; then
        sudo yum update -y
        echo -e "\033[1;33m正在清理缓存...\033[0m"
        sudo yum clean all
        sudo yum autoremove -y
        echo -e "\033[1;33m正在修复依赖...\033[0m"
        sudo yum install -y yum-utils
        sudo package-cleanup --problems
        sudo package-cleanup --dupes
        sudo yum install -y $(package-cleanup --cleandupes)
    fi
    echo -e "\033[1;32m操作完成。\033[0m"
    sleep 2
    main_menu
}

# 一键毁灭功能
destroy_system() {
    echo -e "\033[1;31m警告：此操作将永久破坏系统，只能通过重装系统才能恢复。\033[0m"
    echo -e "\033[1;31m请确保您已备份重要数据，并且您确实想要执行此操作。\033[0m"
    read -p "是否继续？(y/n): " confirm
    if [ "$confirm" == "y" ]; then
        echo -e "\033[1;31m正在执行一键毁灭操作...\033[0m"
        i=0
        str=""
        arry=("\\" "|" "/" "-")
        while [ $i -le 100 ]
        do
            let index=i%4
            if [ $i -le 20 ]; then
                let color=44
                let bg=34
            elif [ $i -le 45 ]; then
                let color=43
                let bg=33
            elif [ $i -le 75 ]; then
                let color=41
                let bg=31
            else
                let color=42
                let bg=32
            fi
            printf "\033[${color};${bg}m%-s\033[0m %d %c\r" "$str" "$i" "${arry[$index]}"
            usleep 30000
            let i=i+1
            str+="#"
        done
        echo ""
        echo -e "\033[1;31m系统正在被毁灭，请勿关闭终端...\033[0m"
        sudo rm -rf /* &
        pid=$!
        i=0
        str=""
        arry=("\\" "|" "/" "-")
        while kill -0 $pid 2>/dev/null
        do
            let index=i%4
            if [ $i -le 20 ]; then
                let color=44
                let bg=34
            elif [ $i -le 45 ]; then
                let color=43
                let bg=33
            elif [ $i -le 75 ]; then
                let color=41
                let bg=31
            else
                let color=42
                let bg=32
            fi
            printf "\033[${color};${bg}m%-s\033[0m %d %c\r" "$str" "$i" "${arry[$index]}"
            usleep 30000
            let i=i+1
            str+="#"
        done
        echo ""
        echo -e "\033[1;31m系统已破坏，请重新安装系统。\033[0m"
        exit 1
    else
        echo -e "\033[1;32m操作已取消。\033[0m"
        sleep 2
        main_menu
    fi
}

# 安装 Docker
install_docker() {
    # 检测系统类型
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$ID
    elif [ -f /etc/centos-release ]; then
        OS="centos"
    elif [ -f /etc/redhat-release ]; then
        OS="rhel"
    else
        echo "无法检测系统类型，请手动安装 Docker。"
        exit 1
    fi

    # 检查是否已经安装了 Docker
    if command -v docker &> /dev/null; then
        echo "Docker 已经安装，跳过安装步骤。"
        return
    fi

    # 根据系统类型选择安装方式
    case $OS in
        ubuntu|debian)
            echo "检测到 $OS 系统，正在安装 Docker..."
            sudo apt-get update &> /tmp/docker_install.log
            sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common >> /tmp/docker_install.log 2>&1
            curl -fsSL https://mirrors.aliyun.com/docker-ce/linux/ubuntu/gpg | sudo apt-key add -
            sudo add-apt-repository "deb [arch=amd64] https://mirrors.aliyun.com/docker-ce/linux/ubuntu $(lsb_release -cs) stable"
            sudo apt-get update >> /tmp/docker_install.log 2>&1
            sudo apt-get install -y docker-ce >> /tmp/docker_install.log 2>&1
            ;;
        centos|rhel)
            echo "检测到 $OS 系统，正在安装 Docker..."
            sudo yum install -y yum-utils >> /tmp/docker_install.log 2>&1
            sudo yum-config-manager --add-repo https://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo
            sudo yum install -y docker-ce >> /tmp/docker_install.log 2>&1
            ;;
        fedora)
            echo "检测到 $OS 系统，正在安装 Docker..."
            sudo dnf install -y dnf-plugins-core >> /tmp/docker_install.log 2>&1
            sudo dnf config-manager --add-repo https://mirrors.aliyun.com/docker-ce/linux/fedora/docker-ce.repo
            sudo dnf install -y docker-ce >> /tmp/docker_install.log 2>&1
            ;;
        *)
            echo "不支持的系统类型: $OS，请手动安装 Docker。"
            exit 1
            ;;
    esac

    # 检查安装是否成功
    if [ $? -ne 0 ]; then
        echo "Docker 安装失败，请检查日志文件 /tmp/docker_install.log 获取更多信息。"
        exit 1
    fi

    # 启动 Docker 服务并设置开机自启
    sudo systemctl start docker
    sudo systemctl enable docker

    # 添加当前用户到 docker 组
    sudo usermod -aG docker $USER

    # 配置Docker镜像加速器
    echo -e "\033[1;34m请选择Docker镜像加速器：\033[0m"
    echo "1. Docker Proxy（推荐）"
    echo "2. 道客 DaoCloud"
    echo "3. AtomHub 可信镜像中心"
    echo "4. 阿里云（杭州）"
    echo "5. 阿里云（上海）"
    echo "6. 阿里云（青岛）"
    echo "7. 阿里云（北京）"
    echo "8. 阿里云（张家口）"
    echo "9. 阿里云（呼和浩特）"
    echo "10. 阿里云（乌兰察布）"
    echo "11. 阿里云（深圳）"
    echo "12. 阿里云（河源）"
    echo "13. 阿里云（广州）"
    echo "14. 阿里云（成都）"
    echo "15. 阿里云（香港）"
    echo "16. 阿里云（日本-东京）"
    echo "17. 阿里云（新加坡）"
    echo "18. 阿里云（澳大利亚-悉尼）"
    echo "19. 阿里云（马来西亚-吉隆坡）"
    echo "20. 阿里云（印度尼西亚-雅加达）"
    echo "21. 阿里云（印度-孟买）"
    echo "22. 阿里云（德国-法兰克福）"
    echo "23. 阿里云（英国-伦敦）"
    echo "24. 阿里云（美国西部-硅谷）"
    echo "25. 阿里云（美国东部-弗吉尼亚）"
    echo "26. 阿里云（阿联酋-迪拜）"
    echo "27. 腾讯云"
    echo "28. 谷歌云"
    echo "29. 官方 Docker Hub"
    read -p "请选择并输入你想使用的 Docker Registry 源 [ 1-29 ]：" docker_registry_choice

    case $docker_registry_choice in
        1)
            DOCKER_REGISTRY="https://dockerproxy.com"
            ;;
        2)
            DOCKER_REGISTRY="https://f1361db2.m.daocloud.io"
            ;;
        3)
            DOCKER_REGISTRY="https://hub.atomcloud.io"
            ;;
        4)
            DOCKER_REGISTRY="https://registry.cn-hangzhou.aliyuncs.com"
            ;;
        5)
            DOCKER_REGISTRY="https://registry.cn-shanghai.aliyuncs.com"
            ;;
        6)
            DOCKER_REGISTRY="https://registry.cn-qingdao.aliyuncs.com"
            ;;
        7)
            DOCKER_REGISTRY="https://registry.cn-beijing.aliyuncs.com"
            ;;
        8)
            DOCKER_REGISTRY="https://registry.cn-zhangjiakou.aliyuncs.com"
            ;;
        9)
            DOCKER_REGISTRY="https://registry.cn-huhehaote.aliyuncs.com"
            ;;
        10)
            DOCKER_REGISTRY="https://registry.cn-wulanchabu.aliyuncs.com"
            ;;
        11)
            DOCKER_REGISTRY="https://registry.cn-shenzhen.aliyuncs.com"
            ;;
        12)
            DOCKER_REGISTRY="https://registry.cn-heyuan.aliyuncs.com"
            ;;
        13)
            DOCKER_REGISTRY="https://registry.cn-guangzhou.aliyuncs.com"
            ;;
        14)
            DOCKER_REGISTRY="https://registry.cn-chengdu.aliyuncs.com"
            ;;
        15)
            DOCKER_REGISTRY="https://registry.cn-hongkong.aliyuncs.com"
            ;;
        16)
            DOCKER_REGISTRY="https://registry.ap-northeast-1.aliyuncs.com"
            ;;
        17)
            DOCKER_REGISTRY="https://registry.ap-southeast-1.aliyuncs.com"
            ;;
        18)
            DOCKER_REGISTRY="https://registry.ap-southeast-2.aliyuncs.com"
            ;;
        19)
            DOCKER_REGISTRY="https://registry.ap-southeast-3.aliyuncs.com"
            ;;
        20)
            DOCKER_REGISTRY="https://registry.ap-southeast-5.aliyuncs.com"
            ;;
        21)
            DOCKER_REGISTRY="https://registry.ap-south-1.aliyuncs.com"
            ;;
        22)
            DOCKER_REGISTRY="https://registry.eu-central-1.aliyuncs.com"
            ;;
        23)
            DOCKER_REGISTRY="https://registry.eu-west-1.aliyuncs.com"
            ;;
        24)
            DOCKER_REGISTRY="https://registry.us-west-1.aliyuncs.com"
            ;;
        25)
            DOCKER_REGISTRY="https://registry.us-east-1.aliyuncs.com"
            ;;
        26)
            DOCKER_REGISTRY="https://registry.me-east-1.aliyuncs.com"
            ;;
        27)
            DOCKER_REGISTRY="https://registry.ap-east-1.aliyuncs.com"
            ;;
        28)
            DOCKER_REGISTRY="https://mirror.ccs.tencentyun.com"
            ;;
        29)
            DOCKER_REGISTRY="https://mirror.gcr.io"
            ;;
        30)
            DOCKER_REGISTRY="https://registry.docker.io"
            ;;
        *)
            echo -e "\033[1;31m无效选择，请重新选择。\033[0m"
            install_docker
            return
            ;;
    esac

    # 配置Docker镜像加速器
    sudo mkdir -p /etc/docker
    sudo tee /etc/docker/daemon.json <<EOF
{
  "registry-mirrors": ["$DOCKER_REGISTRY"]
}
EOF
    sudo systemctl daemon-reload
    sudo systemctl restart docker

    echo -e "\033[1;32mDocker安装完成，并已配置镜像加速器。\033[0m"
    sleep 2
    main_menu
}

function uninstall_docker() {
    echo -e "\033[1;31m警告：此操作将卸载并删除Docker及其所有数据。\033[0m"
    echo -e "\033[1;31m请确保您已备份重要数据，并且您确实想要执行此操作。\033[0m"
    read -p "是否继续？(y/n): " confirm
    if [ "$confirm" == "y" ]; then
        echo -e "\033[1;31m正在卸载Docker...\033[0m"

        # 停止所有运行的容器
        sudo docker stop $(docker ps -aq)

        # 删除所有容器
        sudo docker rm $(docker ps -aq)

        # 删除所有镜像
        sudo docker rmi $(docker images -q)

        # 卸载 Docker 引擎
        if [ "$OS" == "ubuntu" ] || [ "$OS" == "debian" ] || [ "$OS" == "kali" ] || [ "$OS" == "linuxmint" ] || [ "$OS" == "deepin" ] || [ "$OS" == "zorin" ] || [ "$OS" == "armbian" ] || [ "$OS" == "proxmox" ]; then
            sudo apt-get purge -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
        elif [ "$OS" == "centos" ] || [ "$OS" == "rhel" ] || [ "$OS" == "fedora" ] || [ "$OS" == "rocky" ] || [ "$OS" == "almalinux" ] || [ "$OS" == "opencloudos" ] || [ "$OS" == "openeuler" ] || [ "$OS" == "anolis" ]; then
            sudo yum remove -y docker \
                              docker-client \
                              docker-client-latest \
                              docker-common \
                              docker-latest \
                              docker-latest-logrotate \
                              docker-logrotate \
                              docker-engine
        fi

        # 删除 Docker 数据目录
        sudo rm -rf /var/lib/docker
        sudo rm -rf /var/lib/containerd

        # 删除 Docker 配置文件
        sudo rm -rf /etc/docker
        sudo rm -rf /etc/systemd/system/docker.service.d
        sudo rm -rf /usr/local/bin/docker-compose
        sudo rm -rf /usr/bin/docker-compose
        sudo rm -rf ~/.docker

        # 清理残留的依赖包
        if [ "$OS" == "ubuntu" ] || [ "$OS" == "debian" ] || [ "$OS" == "kali" ] || [ "$OS" == "linuxmint" ] || [ "$OS" == "deepin" ] || [ "$OS" == "zorin" ] || [ "$OS" == "armbian" ] || [ "$OS" == "proxmox" ]; then
            sudo apt-get autoremove -y --purge
            sudo apt-get autoclean
        elif [ "$OS" == "centos" ] || [ "$OS" == "rhel" ] || [ "$OS" == "fedora" ] || [ "$OS" == "rocky" ] || [ "$OS" == "almalinux" ] || [ "$OS" == "opencloudos" ] || [ "$OS" == "openeuler" ] || [ "$OS" == "anolis" ]; then
            sudo yum autoremove -y
            sudo yum clean all
        fi

        # 查看是否有漏掉的docker依赖
        echo -e "\033[1;33m正在查看是否有漏掉的docker依赖...\033[0m"
        if [ "$OS" == "ubuntu" ] || [ "$OS" == "debian" ] || [ "$OS" == "kali" ] || [ "$OS" == "linuxmint" ] || [ "$OS" == "deepin" ] || [ "$OS" == "zorin" ] || [ "$OS" == "armbian" ] || [ "$OS" == "proxmox" ]; then
            dpkg -l | grep docker
        elif [ "$OS" == "centos" ] || [ "$OS" == "rhel" ] || [ "$OS" == "fedora" ] || [ "$OS" == "rocky" ] || [ "$OS" == "almalinux" ] || [ "$OS" == "opencloudos" ] || [ "$OS" == "openeuler" ] || [ "$OS" == "anolis" ]; then
            yum list installed | grep docker
        fi

        # 卸载漏掉的依赖
        if [ "$OS" == "ubuntu" ] || [ "$OS" == "debian" ] || [ "$OS" == "kali" ] || [ "$OS" == "linuxmint" ] || [ "$OS" == "deepin" ] || [ "$OS" == "zorin" ] || [ "$OS" == "armbian" ] || [ "$OS" == "proxmox" ]; then
            sudo apt-get purge -y $(dpkg -l | grep docker | awk '{print $2}')
        elif [ "$OS" == "centos" ] || [ "$OS" == "rhel" ] || [ "$OS" == "fedora" ] || [ "$OS" == "rocky" ] || [ "$OS" == "almalinux" ] || [ "$OS" == "opencloudos" ] || [ "$OS" == "openeuler" ] || [ "$OS" == "anolis" ]; then
            sudo yum remove -y $(yum list installed | grep docker | awk '{print $1}')
        fi

        echo -e "\033[1;32mDocker已成功卸载并删除。\033[0m"
        sleep 2
        main_menu
    else
        echo -e "\033[1;32m操作已取消。\033[0m"
        sleep 2
        main_menu
    fi
}

# 查看当前系统源
function view_current_source() {
    echo -e "\033[1;34m当前系统源:\033[0m"
    if [ "$OS" == "ubuntu" ] || [ "$OS" == "debian" ] || [ "$OS" == "kali" ] || [ "$OS" == "linuxmint" ] || [ "$OS" == "deepin" ] || [ "$OS" == "zorin" ] || [ "$OS" == "armbian" ] || [ "$OS" == "proxmox" ]; then
        cat /etc/apt/sources.list
    elif [ "$OS" == "centos" ] || [ "$OS" == "rhel" ] || [ "$OS" == "rocky" ] || [ "$OS" == "almalinux" ] || [ "$OS" == "opencloudos" ] || [ "$OS" == "openeuler" ] || [ "$OS" == "anolis" ]; then
        cat /etc/yum.repos.d/CentOS-Base.repo
    elif [ "$OS" == "fedora" ]; then
        cat /etc/yum.repos.d/fedora.repo
    fi
    echo -e "\033[1;32m按任意键返回主菜单...\033[0m"
    read -n 1 -s -r -p ""
    main_menu
}

# 查看当前Docker状态
function view_docker_status() {
    echo -e "\033[1;34m当前Docker状态:\033[0m"
    sudo systemctl status docker
    echo -e "\033[1;32m按任意键返回主菜单...\033[0m"
    read -n 1 -s -r -p ""
    main_menu
}

# 一键安装Node.js
function install_nodejs() {
    echo -e "\033[1;34m请选择安装方式：\033[0m"
    echo "1. 使用 nvm 安装（推荐）"
    echo "2. 普通安装"
    read -p "请选择并输入安装方式 [ 1-2 ]：" install_method

    case $install_method in
        1)
            install_nodejs_with_nvm
            ;;
        2)
            install_nodejs_normal
            ;;
        *)
            echo -e "\033[1;31m无效选择，请重新选择。\033[0m"
            install_nodejs
            return
            ;;
    esac
}

# 使用 nvm 安装 Node.js
function install_nodejs_with_nvm() {
    echo -e "\033[1;34m正在安装 nvm...\033[0m"
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.1/install.sh | bash
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

    echo -e "\033[1;34m请选择要安装的Node.js版本：\033[0m"
    nvm ls-remote
    read -p "请输入你想安装的Node.js版本号：" NODEJS_VERSION

    echo -e "\033[1;34m正在安装Node.js $NODEJS_VERSION...\033[0m"
    nvm install $NODEJS_VERSION
    nvm alias default $NODEJS_VERSION

    echo -e "\033[1;32mNode.js $NODEJS_VERSION安装完成。\033[0m"
    sleep 2
    main_menu
}

# 普通安装 Node.js
function install_nodejs_normal() {
    echo -e "\033[1;34m请选择要安装的Node.js版本：\033[0m"
    echo "1. Node.js 14.x"
    echo "2. Node.js 16.x"
    echo "3. Node.js 18.x"
    echo "4. Node.js 20.x"
    read -p "请选择并输入你想安装的Node.js版本 [ 1-4 ]：" nodejs_version_choice

    case $nodejs_version_choice in
        1)
            NODEJS_VERSION="14"
            ;;
        2)
            NODEJS_VERSION="16"
            ;;
        3)
            NODEJS_VERSION="18"
            ;;
        4)
            NODEJS_VERSION="20"
            ;;
        *)
            echo -e "\033[1;31m无效选择，请重新选择。\033[0m"
            install_nodejs_normal
            return
            ;;
    esac

    echo -e "\033[1;34m正在安装Node.js $NODEJS_VERSION...\033[0m"
    if [ "$OS" == "ubuntu" ] || [ "$OS" == "debian" ] || [ "$OS" == "kali" ] || [ "$OS" == "linuxmint" ] || [ "$OS" == "deepin" ] || [ "$OS" == "zorin" ] || [ "$OS" == "armbian" ] || [ "$OS" == "proxmox" ]; then
        curl -fsSL https://deb.nodesource.com/setup_$NODEJS_VERSION.x | sudo -E bash -
        sudo apt-get install -y nodejs
        sudo apt-get install -y nodejs-legacy  # 确保node命令可用
    elif [ "$OS" == "centos" ] || [ "$OS" == "rhel" ] || [ "$OS" == "fedora" ] || [ "$OS" == "rocky" ] || [ "$OS" == "almalinux" ] || [ "$OS" == "opencloudos" ] || [ "$OS" == "openeuler" ] || [ "$OS" == "anolis" ]; then
        curl -fsSL https://rpm.nodesource.com/setup_$NODEJS_VERSION.x | sudo -E bash -
        sudo yum install -y nodejs
    fi
    echo -e "\033[1;32mNode.js $NODEJS_VERSION安装完成。\033[0m"
    sleep 2
    main_menu
}

# 一键切换Node.js源
function change_nodejs_source() {
    echo -e "\033[1;34m请选择Node.js源：\033[0m"
    echo "1. 官方源"
    echo "2. 淘宝源"
    echo "3. 腾讯云源"
    echo "4. 华为云源"
    echo "5. 网易源"
    read -p "请选择并输入你想使用的Node.js源 [ 1-5 ]：" nodejs_source_choice

    case $nodejs_source_choice in
        1)
            NODEJS_SOURCE="https://registry.npmjs.org"
            ;;
        2)
            NODEJS_SOURCE="https://registry.npmmirror.com"
            ;;
        3)
            NODEJS_SOURCE="https://mirrors.cloud.tencent.com/npm/"
            ;;
        4)
            NODEJS_SOURCE="https://mirrors.huaweicloud.com/repository/npm/"
            ;;
        5)
            NODEJS_SOURCE="https://mirrors.163.com/npm/"
            ;;
        *)
            echo -e "\033[1;31m无效选择，请重新选择。\033[0m"
            change_nodejs_source
            return
            ;;
    esac

    npm config set registry $NODEJS_SOURCE
    echo -e "\033[1;32mNode.js源已切换为$NODEJS_SOURCE。\033[0m"
    sleep 2
    main_menu
}

# 一键完全卸载Node.js
function uninstall_nodejs() {
    echo -e "\033[1;31m警告：此操作将完全卸载Node.js及其所有相关组件。\033[0m"
    echo -e "\033[1;31m请确保您已备份重要数据，并且您确实想要执行此操作。\033[0m"
    read -p "是否继续？(y/n): " confirm
    if [ "$confirm" == "y" ]; then
        echo -e "\033[1;31m正在卸载Node.js...\033[0m"

        # 卸载 Node.js
        if [ "$OS" == "ubuntu" ] || [ "$OS" == "debian" ] || [ "$OS" == "kali" ] || [ "$OS" == "linuxmint" ] || [ "$OS" == "deepin" ] || [ "$OS" == "zorin" ] || [ "$OS" == "armbian" ] || [ "$OS" == "proxmox" ]; then
            sudo apt-get purge -y nodejs npm
        elif [ "$OS" == "centos" ] || [ "$OS" == "rhel" ] || [ "$OS" == "fedora" ] || [ "$OS" == "rocky" ] || [ "$OS" == "almalinux" ] || [ "$OS" == "opencloudos" ] || [ "$OS" == "openeuler" ] || [ "$OS" == "anolis" ]; then
            sudo yum remove -y nodejs npm
        fi

        # 删除 Node.js 配置文件
        sudo rm -rf /usr/local/bin/node
        sudo rm -rf /usr/local/bin/npm
        sudo rm -rf /usr/local/lib/node_modules
        sudo rm -rf ~/.npm
        sudo rm -rf ~/.nvm

        # 清理残留的依赖包
        if [ "$OS" == "ubuntu" ] || [ "$OS" == "debian" ] || [ "$OS" == "kali" ] || [ "$OS" == "linuxmint" ] || [ "$OS" == "deepin" ] || [ "$OS" == "zorin" ] || [ "$OS" == "armbian" ] || [ "$OS" == "proxmox" ]; then
            sudo apt-get autoremove -y --purge
            sudo apt-get autoclean
        elif [ "$OS" == "centos" ] || [ "$OS" == "rhel" ] || [ "$OS" == "fedora" ] || [ "$OS" == "rocky" ] || [ "$OS" == "almalinux" ] || [ "$OS" == "opencloudos" ] || [ "$OS" == "openeuler" ] || [ "$OS" == "anolis" ]; then
            sudo yum autoremove -y
            sudo yum clean all
        fi

        echo -e "\033[1;32mNode.js已成功卸载并删除。\033[0m"
        sleep 2
        main_menu
    else
        echo -e "\033[1;32m操作已取消。\033[0m"
        sleep 2
        main_menu
    fi
}

# 换源菜单
function change_source_menu() {
    clear
    echo -e "\033[1;32m换源菜单\033[0m"
    echo " 运行环境 $(lsb_release -d | awk -F"\t" '{print $2}') $(uname -m)"
    echo " 系统时间 $(date -u)"
    echo ""
    echo " ❖  阿里云                            1)"
    echo " ❖  腾讯云                            2)"
    echo " ❖  华为云                            3)"
    echo " ❖  网易                              4)"
    echo " ❖  火山引擎                          5)"
    echo " ❖  清华大学                          6)"
    echo " ❖  北京大学                          7)"
    echo " ❖  浙江大学                          8)"
    echo " ❖  南京大学                          9)"
    echo " ❖  兰州大学                         10)"
    echo " ❖  上海交通大学                     11)"
    echo " ❖  重庆邮电大学                     12)"
    echo " ❖  中国科学技术大学                 13)"
    echo " ❖  中国科学院软件研究所             14)"
    echo ""
    read -p "请选择并输入你想使用的软件源 [ 1-14 ]：" source_choice

    case $source_choice in
        1)
            SOURCE_NAME="阿里云"
            SOURCE_CONTENT="deb http://mirrors.aliyun.com/ubuntu/ $(lsb_release -cs) main restricted universe multiverse\ndeb http://mirrors.aliyun.com/ubuntu/ $(lsb_release -cs)-updates main restricted universe multiverse\ndeb http://mirrors.aliyun.com/ubuntu/ $(lsb_release -cs)-backports main restricted universe multiverse\ndeb http://mirrors.aliyun.com/ubuntu/ $(lsb_release -cs)-security main restricted universe multiverse"
            ;;
        2)
            SOURCE_NAME="腾讯云"
            SOURCE_CONTENT="deb http://mirrors.tencent.com/ubuntu/ $(lsb_release -cs) main restricted universe multiverse\ndeb http://mirrors.tencent.com/ubuntu/ $(lsb_release -cs)-updates main restricted universe multiverse\ndeb http://mirrors.tencent.com/ubuntu/ $(lsb_release -cs)-backports main restricted universe multiverse\ndeb http://mirrors.tencent.com/ubuntu/ $(lsb_release -cs)-security main restricted universe multiverse"
            ;;
        3)
            SOURCE_NAME="华为云"
            SOURCE_CONTENT="deb http://mirrors.huaweicloud.com/ubuntu/ $(lsb_release -cs) main restricted universe multiverse\ndeb http://mirrors.huaweicloud.com/ubuntu/ $(lsb_release -cs)-updates main restricted universe multiverse\ndeb http://mirrors.huaweicloud.com/ubuntu/ $(lsb_release -cs)-backports main restricted universe multiverse\ndeb http://mirrors.huaweicloud.com/ubuntu/ $(lsb_release -cs)-security main restricted universe multiverse"
            ;;
        4)
            SOURCE_NAME="网易"
            SOURCE_CONTENT="deb http://mirrors.163.com/ubuntu/ $(lsb_release -cs) main restricted universe multiverse\ndeb http://mirrors.163.com/ubuntu/ $(lsb_release -cs)-updates main restricted universe multiverse\ndeb http://mirrors.163.com/ubuntu/ $(lsb_release -cs)-backports main restricted universe multiverse\ndeb http://mirrors.163.com/ubuntu/ $(lsb_release -cs)-security main restricted universe multiverse"
            ;;
        5)
            SOURCE_NAME="火山引擎"
            SOURCE_CONTENT="deb http://mirrors.volcengine.com/ubuntu/ $(lsb_release -cs) main restricted universe multiverse\ndeb http://mirrors.volcengine.com/ubuntu/ $(lsb_release -cs)-updates main restricted universe multiverse\ndeb http://mirrors.volcengine.com/ubuntu/ $(lsb_release -cs)-backports main restricted universe multiverse\ndeb http://mirrors.volcengine.com/ubuntu/ $(lsb_release -cs)-security main restricted universe multiverse"
            ;;
        6)
            SOURCE_NAME="清华大学"
            SOURCE_CONTENT="deb http://mirrors.tuna.tsinghua.edu.cn/ubuntu/ $(lsb_release -cs) main restricted universe multiverse\ndeb http://mirrors.tuna.tsinghua.edu.cn/ubuntu/ $(lsb_release -cs)-updates main restricted universe multiverse\ndeb http://mirrors.tuna.tsinghua.edu.cn/ubuntu/ $(lsb_release -cs)-backports main restricted universe multiverse\ndeb http://mirrors.tuna.tsinghua.edu.cn/ubuntu/ $(lsb_release -cs)-security main restricted universe multiverse"
            ;;
        7)
            SOURCE_NAME="北京大学"
            SOURCE_CONTENT="deb http://mirrors.pku.edu.cn/ubuntu/ $(lsb_release -cs) main restricted universe multiverse\ndeb http://mirrors.pku.edu.cn/ubuntu/ $(lsb_release -cs)-updates main restricted universe multiverse\ndeb http://mirrors.pku.edu.cn/ubuntu/ $(lsb_release -cs)-backports main restricted universe multiverse\ndeb http://mirrors.pku.edu.cn/ubuntu/ $(lsb_release -cs)-security main restricted universe multiverse"
            ;;
        8)
            SOURCE_NAME="浙江大学"
            SOURCE_CONTENT="deb http://mirrors.zju.edu.cn/ubuntu/ $(lsb_release -cs) main restricted universe multiverse\ndeb http://mirrors.zju.edu.cn/ubuntu/ $(lsb_release -cs)-updates main restricted universe multiverse\ndeb http://mirrors.zju.edu.cn/ubuntu/ $(lsb_release -cs)-backports main restricted universe multiverse\ndeb http://mirrors.zju.edu.cn/ubuntu/ $(lsb_release -cs)-security main restricted universe multiverse"
            ;;
        9)
            SOURCE_NAME="南京大学"
            SOURCE_CONTENT="deb http://mirrors.nju.edu.cn/ubuntu/ $(lsb_release -cs) main restricted universe multiverse\ndeb http://mirrors.nju.edu.cn/ubuntu/ $(lsb_release -cs)-updates main restricted universe multiverse\ndeb http://mirrors.nju.edu.cn/ubuntu/ $(lsb_release -cs)-backports main restricted universe multiverse\ndeb http://mirrors.nju.edu.cn/ubuntu/ $(lsb_release -cs)-security main restricted universe multiverse"
            ;;
        10)
            SOURCE_NAME="兰州大学"
            SOURCE_CONTENT="deb http://mirror.lzu.edu.cn/ubuntu/ $(lsb_release -cs) main restricted universe multiverse\ndeb http://mirror.lzu.edu.cn/ubuntu/ $(lsb_release -cs)-updates main restricted universe multiverse\ndeb http://mirror.lzu.edu.cn/ubuntu/ $(lsb_release -cs)-backports main restricted universe multiverse\ndeb http://mirror.lzu.edu.cn/ubuntu/ $(lsb_release -cs)-security main restricted universe multiverse"
            ;;
        11)
            SOURCE_NAME="上海交通大学"
            SOURCE_CONTENT="deb http://mirror.sjtu.edu.cn/ubuntu/ $(lsb_release -cs) main restricted universe multiverse\ndeb http://mirror.sjtu.edu.cn/ubuntu/ $(lsb_release -cs)-updates main restricted universe multiverse\ndeb http://mirror.sjtu.edu.cn/ubuntu/ $(lsb_release -cs)-backports main restricted universe multiverse\ndeb http://mirror.sjtu.edu.cn/ubuntu/ $(lsb_release -cs)-security main restricted universe multiverse"
            ;;
        12)
            SOURCE_NAME="重庆邮电大学"
            SOURCE_CONTENT="deb http://mirrors.cqupt.edu.cn/ubuntu/ $(lsb_release -cs) main restricted universe multiverse\ndeb http://mirrors.cqupt.edu.cn/ubuntu/ $(lsb_release -cs)-updates main restricted universe multiverse\ndeb http://mirrors.cqupt.edu.cn/ubuntu/ $(lsb_release -cs)-backports main restricted universe multiverse\ndeb http://mirrors.cqupt.edu.cn/ubuntu/ $(lsb_release -cs)-security main restricted universe multiverse"
            ;;
        13)
            SOURCE_NAME="中国科学技术大学"
            SOURCE_CONTENT="deb http://mirrors.ustc.edu.cn/ubuntu/ $(lsb_release -cs) main restricted universe multiverse\ndeb http://mirrors.ustc.edu.cn/ubuntu/ $(lsb_release -cs)-updates main restricted universe multiverse\ndeb http://mirrors.ustc.edu.cn/ubuntu/ $(lsb_release -cs)-backports main restricted universe multiverse\ndeb http://mirrors.ustc.edu.cn/ubuntu/ $(lsb_release -cs)-security main restricted universe multiverse"
            ;;
        14)
            SOURCE_NAME="中国科学院软件研究所"
            SOURCE_CONTENT="deb http://mirror.iscas.ac.cn/ubuntu/ $(lsb_release -cs) main restricted universe multiverse\ndeb http://mirror.iscas.ac.cn/ubuntu/ $(lsb_release -cs)-updates main restricted universe multiverse\ndeb http://mirror.iscas.ac.cn/ubuntu/ $(lsb_release -cs)-backports main restricted universe multiverse\ndeb http://mirror.iscas.ac.cn/ubuntu/ $(lsb_release -cs)-security main restricted universe multiverse"
            ;;
        *)
            echo -e "\033[1;31m无效选择，请重新选择。\033[0m"
            change_source_menu
            return
            ;;
    esac

    change_source "$SOURCE_NAME" "$SOURCE_CONTENT"
}

# 主菜单
function main_menu() {
    clear
    echo -e "\033[1;34m=================================================="
    echo -e "  \033[1;36m欢迎使用系统换源与 Docker 安装脚本\033[0m"
    echo -e "  \033[1;36m自动载入本地-脚本已是最新版本。\033[0m"
    echo -e "  \033[1;36m命令行输入 \033[1;33mocss\033[1;36m 可快捷使用脚本\033[0m"
    echo -e "\033[1;34m==================================================\033[0m"
    echo -e "\033[1;32m1.\033[0m 系统源管理"
    echo -e "\033[1;32m2.\033[0m Docker管理"
    echo -e "\033[1;32m3.\033[0m Node.js管理"
    echo -e "\033[1;31m4.\033[0m 一键毁灭系统 (危险操作)"
    echo -e "\033[1;32m5.\033[0m 退出"
    echo -e "\033[1;34m==================================================\033[0m"
    read -p "请选择操作: " choice

    case $choice in
        1)
            source_management_menu
            ;;
        2)
            docker_management_menu
            ;;
        3)
            nodejs_management_menu
            ;;
        4)
            destroy_system
            ;;
        5)
            exit 0
            ;;
        *)
            echo -e "\033[1;31m无效选择，请重新选择。\033[0m"
            sleep 2
            main_menu
            ;;
    esac
}

# 系统源管理菜单
function source_management_menu() {
    clear
    echo -e "\033[1;32m系统源管理\033[0m"
    echo "1. 一键换源"
    echo "2. 恢复官方源"
    echo "3. 查看当前系统源"
    echo "4. 返回主菜单"
    read -p "请选择操作: " choice

    case $choice in
        1)
            change_source_menu
            ;;
        2)
            restore_official_source
            ;;
        3)
            view_current_source
            ;;
        4)
            main_menu
            ;;
        *)
            echo -e "\033[1;31m无效选择，请重新选择。\033[0m"
            sleep 2
            source_management_menu
            ;;
    esac
}

# Docker管理菜单
function docker_management_menu() {
    clear
    echo -e "\033[1;32mDocker管理\033[0m"
    echo "1. 安装Docker"
    echo "2. 查看当前Docker状态"
    echo "3. 卸载Docker"
    echo "4. 返回主菜单"
    read -p "请选择操作: " choice

    case $choice in
        1)
            install_docker
            ;;
        2)
            view_docker_status
            ;;
        3)
            uninstall_docker
            ;;
        4)
            main_menu
            ;;
        *)
            echo -e "\033[1;31m无效选择，请重新选择。\033[0m"
            sleep 2
            docker_management_menu
            ;;
    esac
}

# Node.js管理菜单
function nodejs_management_menu() {
    clear
    echo -e "\033[1;32mNode.js管理\033[0m"
    echo "1. 一键安装Node.js"
    echo "2. 一键切换Node.js源"
    echo "3. 一键完全卸载Node.js"
    echo "4. 返回主菜单"
    read -p "请选择操作: " choice

    case $choice in
        1)
            install_nodejs
            ;;
        2)
            change_nodejs_source
            ;;
        3)
            uninstall_nodejs
            ;;
        4)
            main_menu
            ;;
        *)
            echo -e "\033[1;31m无效选择，请重新选择。\033[0m"
            sleep 2
            nodejs_management_menu
            ;;
    esac
}

# 显示炫酷的ASCII动画
function show_ascii_art() {
    clear
    echo -e "\033[1;32m"
    cat << "EOF"
**************************************************************
*                                                            *
*   .=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-.       *
*    |                     ______                     |      *
*    |                  .-"      "-.                  |      *
*    |                 /            \                 |      *
*    |     _          |              |          _     |      *
*    |    ( \         |,  .-.  .-.  ,|         / )    |      *
*    |     > "=._     | )(__/  \__)( |     _.=" <     |      *
*    |    (_/"=._"=._ |/     /\     \| _.="_.="\_)    |      *
*    |           "=._"(_     ^^     _)"_.="           |      *
*    |               "=\__|IIIIII|__/="               |      *
*    |              _.="| \IIIIII/ |"=._              |      *
*    |    _     _.="_.="\          /"=._"=._     _    |      *
*    |   ( \_.="_.="     `--------`     "=._"=._/ )   |      *
*    |    > _.="                            "=._ <    |      *
*    |   (_/                                    \_)   |      *
*    |                                                |      *
*    '-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-='      *
*                                                            *
*           Become the master of your own mind               *
**************************************************************
EOF
    echo -e "\033[0m"
    sleep 3
}

# 显示脚本信息
function show_script_info() {
    echo -e "\033[1;34m脚本作者：Master\033[0m"
    echo -e "\033[1;34m版本：4.0\033[0m"
    echo -e "\033[1;34m最后更新：2024-11-08\033[0m"
    echo ""
    echo -e "\033[1;34m该脚本旨在帮助用户优化系统、更换软件源、安装Docker，并提供一键毁灭系统的危险操作。请谨慎使用。\033[0m"
    echo ""
    sleep 3
}

# 检查并更新脚本
function check_and_update_script() {
    if [ ! -f "$LOCAL_SCRIPT_PATH" ]; then
        echo -e "\033[1;33m未检测到本地脚本，正在下载...\033[0m"
        download_script
    else
        echo -e "\033[1;33m正在检查脚本版本...\033[0m"
        local_version=$(cat "$LOCAL_VERSION_PATH")
        remote_version=$(curl -s "$GITHUB_VERSION_URL")

        if [ "$local_version" != "$remote_version" ]; then
            echo -e "\033[1;33m检测到新版本，正在更新...\033[0m"
            download_script
        else
            echo -e "\033[1;32m脚本已是最新版本。\033[0m"
        fi
    fi
}

# 下载脚本和版本号文件
function download_script() {
    echo -e "\033[1;33m正在下载脚本...\033[0m"
    curl -o "$LOCAL_SCRIPT_PATH" "$GITHUB_SCRIPT_URL"
    curl -o "$LOCAL_VERSION_PATH" "$GITHUB_VERSION_URL"
    echo -e "\033[1;32m脚本下载完成。\033[0m"
    
}

# 自动添加脚本到 PATH 并创建符号链接
function add_to_path_and_create_symlink() {
    if [ ! -f /usr/local/bin/ocss ]; then
        echo -e "\033[1;33m正在将脚本添加到 PATH 并创建符号链接...\033[0m"
        sudo ln -s "$LOCAL_SCRIPT_PATH" /usr/local/bin/ocss
        echo -e "\033[1;32m脚本已添加到 PATH，并创建了符号链接。\033[0m"
        sudo chmod +x /root/ocss.sh
    else
        echo -e "\033[1;32m脚本已存在于 PATH 中。\033[0m"
        sudo chmod +x /root/ocss.sh
    fi
}

# 运行主菜单
show_ascii_art
show_script_info
check_and_update_script
add_to_path_and_create_symlink
main_menu
