#!/bin/bash
set -e

echo "=== 🚀 Preparando Arch Linux para Desenvolvimento Premium ==="

# =============================
# 1. Configurações iniciais
# =============================
ln -sf /usr/share/zoneinfo/America/Sao_Paulo /etc/localtime
hwclock --systohc

sed -i 's/^#\(en_US.UTF-8\)/\1/' /etc/locale.gen
sed -i 's/^#\(pt_BR.UTF-8\)/\1/' /etc/locale.gen
locale-gen
echo "LANG=pt_BR.UTF-8" > /etc/locale.conf

echo "arch-dev" > /etc/hostname
cat <<EOF > /etc/hosts
127.0.0.1   localhost
::1         localhost
127.0.1.1   arch-dev.localdomain arch-dev
EOF

# =============================
# 2. Configura pacman
# =============================
echo "=== Otimizando pacman ==="
sed -i 's/^#ParallelDownloads.*/ParallelDownloads = 15/' /etc/pacman.conf
sed -i 's/^#Color/Color/' /etc/pacman.conf
sed -i 's/^#VerbosePkgLists/VerbosePkgLists/' /etc/pacman.conf

if ! grep -q "^\[multilib\]" /etc/pacman.conf; then
    cat <<EOF >> /etc/pacman.conf

[multilib]
Include = /etc/pacman.d/mirrorlist
EOF
fi

pacman -Syu --noconfirm

# =============================
# 3. Pacotes base
# =============================
echo "=== Instalando pacotes essenciais ==="
pacman -S --noconfirm --needed base-devel git curl wget vim nvim nano unzip zip tar openssh htop man-db man-pages sudo bash-completion networkmanager inetutils net-tools reflector rsync lsof which gparted tree cmake make gcc clang pkgconf

systemctl enable NetworkManager

# =============================
# 4. Linguagens e ambientes
# =============================
echo "=== Instalando linguagens ==="
pacman -S --noconfirm --needed python python-pip nodejs npm go rust java-runtime-common jdk-openjdk maven gradle docker docker-compose kubectl helm

#systemctl enable docker

# =============================
# 5. Bancos de dados
# =============================
echo "=== Instalando bancos de dados ==="
pacman -S --noconfirm --needed postgresql mariadb redis sqlite

systemctl enable postgresql
#systemctl enable mariadb
#systemctl enable redis

# =============================
# 6. Ferramentas CLI
# =============================
echo "=== Instalando utilitários ==="
pacman -S --noconfirm --needed neofetch tmux fzf bat exa ripgrep jq lazygit btop

# =============================
# 7. Instalando Yay (AUR)
# =============================
echo "=== Instalando Yay (AUR) ==="
cd /opt
git clone https://aur.archlinux.org/yay.git
chown -R root:root yay
cd yay
sudo -u root makepkg -si --noconfirm
cd /
rm -rf /opt/yay

# =============================
# 8. Apps do AUR e dev tools extras
# =============================
echo "=== Instalando apps do AUR ==="
sudo -u root yay -S --noconfirm visual-studio-code-bin postman-bin dbeaver insomnia brave-bin discord

# =============================
# 9. Configuração do Node.js
# =============================
echo "=== Configurando gerenciadores de pacotes JS ==="
npm install -g yarn pnpm

# =============================
# 10. Criar usuário
# =============================
echo "=== Criando usuário dev ==="
read -p "Digite o nome do usuário: " USERNAME
useradd -m -G wheel,docker -s /bin/zsh "$USERNAME"
passwd "$USERNAME"

# Libera sudo
sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers

# =============================
# 11. Zsh + Oh My Zsh + Powerlevel10k
# =============================
echo "=== Configurando Zsh e Powerlevel10k ==="
pacman -S --noconfirm --needed zsh zsh-completions zsh-syntax-highlighting zsh-autosuggestions

sudo -u "$USERNAME" sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
sudo -u "$USERNAME" git clone --depth=1 https://github.com/romkatv/powerlevel10k.git /home/$USERNAME/.oh-my-zsh/custom/themes/powerlevel10k

# Define tema Powerlevel10k
sed -i 's|^ZSH_THEME=.*|ZSH_THEME="powerlevel10k/powerlevel10k"|' /home/$USERNAME/.zshrc

# Adiciona plugins ao Zsh
sed -i 's/plugins=(git)/plugins=(git docker kubectl zsh-autosuggestions zsh-syntax-highlighting)/' /home/$USERNAME/.zshrc

# =============================
# 12. Dotfiles customizados
# =============================
echo "=== ⚙️ Configurando alias e atalhos ==="
cat <<'EOF' >> /home/$USERNAME/.zshrc

# === Atalhos gerais ===
alias ls='exa --icons'
alias ll='exa -lah --icons'
alias cat='bat'ee
alias grep='rg'
alias gs='git status'
alias gc='git commit'
alias gp='git push'
alias gl='git log --oneline --graph --decorate'
alias d='docker'
alias dc='docker compose'
alias k='kubectl'
alias kctx='kubectl config use-context'
alias pods='kubectl get pods -A'
EOF

chown "$USERNAME":"$USERNAME" /home/$USERNAME/.zshrc

# =============================
# 13. Limpeza final
# =============================
echo "=== 🧹 Limpando sistema ==="
pacman -Scc --noconfirm

echo "=== ✅ Setup Premium concluído! Reinicie para aplicar tudo ==="
