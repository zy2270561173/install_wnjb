#!/bin/bash

# 脚本头部信息
echo "欢迎使用：一键多功能部署脚本。"
echo "-------------------------"
echo "脚本作者：慕沄"
echo "云服务器提供商：ZIC云数据 idc.zicyun.cn"
echo "-------------------------"

# 检查系统类型
check_os() {
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        OS=$NAME
        VER=$VERSION_ID
        if [[ "$OS" == "CentOS" ]]; then
            BASEARCH=$(uname -m)
        fi
    else
        echo "错误：无法识别的操作系统"
        exit 1
    fi
}

# 检查并设置包管理器
set_package_manager() {
    if command -v apt-get >/dev/null 2>&1; then
        PKG_MGR="apt-get"
    elif command -v yum >/dev/null 2>&1; then
        PKG_MGR="yum"
    else
        echo "错误：未安装apt-get或yum"
        exit 1
    fi
}



# 安装Docker
install_docker() {
    if ! docker --version &> /dev/null; then
        echo "Docker未安装，开始安装..."

        if [[ "$PKG_MGR" == "apt-get" ]]; then
            # 对于Debian/Ubuntu系统
            local codename=$(lsb_release -cs)
            echo "deb [arch=amd64] https://mirrors.tuna.tsinghua.edu.cn/docker-ce/linux/debian $codename stable" | sudo tee /etc/apt/sources.list.d/docker-ce.list
            curl -fsSL https://mirrors.tuna.tsinghua.edu.cn/docker-ce/linux/debian/gpg | sudo apt-key add -
            sudo apt-get update
            sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common
            sudo apt-get update
            sudo apt-get install -y docker-ce docker-ce-cli containerd.io
        elif [[ "$PKG_MGR" == "yum" ]]; then
            # 对于CentOS系统
            local centos_version
            centos_version=$(rpm -E %rhel)
            echo "CentOS版本: $centos_version"
            if [[ "$centos_version" -ge 7 ]]; then
                yum install -y yum-utils
                yum-config-manager --add-repo https://mirrors.tuna.tsinghua.edu.cn/docker-ce/linux/centos/docker-ce.repo
                yum makecache fast
                yum install -y docker-ce docker-ce-cli containerd.io
            else
                echo "该CentOS版本不支持Docker CE，需要CentOS 7或更高版本。"
                return 1
            fi
        fi

        # 启动并使Docker服务在开机时自动启动
        sudo systemctl start docker
        sudo systemctl enable docker

        echo "Docker安装完成。"
    else
        echo "Docker已安装，版本：$(docker --version)"
    fi
}
# 安装宝塔面板
install_baota_panel() {
    echo "正在安装宝塔面板..."
    wget -O bt_install.sh https://download.bt.cn/install/install_lts.sh && bash bt_install.sh ed8484bec
    # 宝塔面板安装后需要重启，这里不提供自动重启的脚本
    echo "宝塔面板安装完成，请重启服务器后使用。"
    rm bt_install.sh
}

# 更新系统依赖
update_system() {
    echo "正在更新系统依赖..."
    if [[ "$PKG_MGR" == "apt-get" ]]; then
        sudo $PKG_MGR update && sudo $PKG_MGR upgrade -y
    elif [[ "$PKG_MGR" == "yum" ]]; then
        sudo $PKG_MGR check-update && sudo $PKG_MGR upgrade -y
    fi
}


# 设置国内源
set_mirror() {
    echo "选择要设置的镜像源:"
    echo "1: 阿里云"
    echo "2: 清华大学"
    # 移除了中国科技大学的选项，因为您可能需要一个可靠的源
    read -p "请输入选项（1-2）：" mirror_num

    case $mirror_num in
        1)
        
            mirror_url="https://mirrors.aliyun.com/$(echo "$OS" | awk '{print tolower($0)}')"
            echo "当前系统：$(echo "$OS" | awk '{print tolower($0)}')"
            ;;
        2)
        
            mirror_url="https://mirrors.tuna.tsinghua.edu.cn/$(echo "$OS" | awk '{print tolower($0)}')"
            echo "当前系统：$(echo "$OS" | awk '{print tolower($0)}')"
            ;;
        *)
            echo "无效的输入，请输入1或2"
            exit 1
            ;;
    esac

    echo "设置$mirror_url镜像源..."
    if [[ "$PKG_MGR" == "apt-get" ]]; then
        echo "deb [arch=amd64] $mirror_url/$VER main" | sudo tee /etc/apt/sources.list.d/centos.list
    elif [[ "$PKG_MGR" == "yum" ]]; then
        sed -i "s|^baseurl=.*|baseurl=$mirror_url|" /etc/yum.repos.d/*.repo
    fi
    echo "镜像源设置完成，请执行以下命令更新缓存："
    if [[ "$PKG_MGR" == "apt-get" ]]; then
        echo "sudo apt-get update"
    elif [[ "$PKG_MGR" == "yum" ]]; then
        echo "sudo yum makecache"
    fi
}
# 设置中国时区（示例）
set_timezone() {
    echo "设置中国时区..."
    sudo timedatectl set-timezone 'Asia/Shanghai'
}

# 主菜单函数
main_menu() {
    while true; do
        echo "请选择要执行的操作："
        echo " 0. 退出安装脚本"
        echo " 1. 安装Docker"
        echo " 2. 安装宝塔面板"
        echo " 3. 更新系统依赖"
        echo " 4. 设置国内源"
        echo " 5. 设置中国时区"
        read -p "请输入选项：" option
        
        case $option in
            0) exit 0 ;;
            1) install_docker ;;
            2) install_baota_panel ;;
            3) update_system ;;
            4) set_mirror ;;
            5) set_timezone ;;
            *) echo "无效的选项，请重新输入！" ;;
        esac
    done
}
# if_OS1(){
# OS1= "$(echo "$OS" | awk '{print tolower($0)}')"
        # echo "$OS1"
# }
# 脚本执行入口
check_os
#if_OS1
set_package_manager
main_menu