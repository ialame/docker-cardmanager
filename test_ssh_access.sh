#!/bin/bash

echo "🔍 Test d'accès SSH à Bitbucket"
echo "==============================="

# 1. Vérifier la clé SSH
echo "📋 Vérification de la clé SSH..."
if [ -f "$HOME/.ssh/bitbucket_ed25519" ]; then
    echo "✅ Clé SSH trouvée : $HOME/.ssh/r.alhajjaj@pcagrade.fr"

    # Vérifier les permissions
    perms=$(stat -f "%OLp" "$HOME/.ssh/bitbucket_ed25519" 2>/dev/null || stat -c "%a" "$HOME/.ssh/bitbucket_ed25519" 2>/dev/null)
    echo "🔐 Permissions : $perms"

    if [ "$perms" = "600" ]; then
        echo "✅ Permissions correctes"
    else
        echo "⚠️ Permissions incorrectes, correction..."
        chmod 600 "$HOME/.ssh/bitbucket_ed25519"
    fi

    # Afficher l'empreinte de la clé publique
    if [ -f "$HOME/.ssh/bitbucket_ed25519.pub" ]; then
        echo ""
        echo "🔑 Empreinte de votre clé publique :"
        ssh-keygen -lf "$HOME/.ssh/bitbucket_ed25519.pub" 2>/dev/null || echo "Impossible de lire l'empreinte"

        echo ""
        echo "📋 Votre clé publique (à ajouter à Bitbucket si pas déjà fait) :"
        cat "$HOME/.ssh/bitbucket_ed25519.pub"
    fi
else
    echo "❌ Clé SSH non trouvée à $HOME/.ssh/bitbucket_ed25519"
    echo "💡 Générez une clé SSH :"
    echo "   ssh-keygen -t rsa -b 4096 -C 'r.alhajjaj@pcagrade.fr'"
    exit 1
fi

# 2. Test de connexion SSH à Bitbucket avec la clé spécifique
echo ""
echo "🧪 Test de connexion SSH à Bitbucket avec clé ED25519..."
ssh_result=$(ssh -i "$SSH_KEY_PATH" -T git@bitbucket.org -o ConnectTimeout=10 -o BatchMode=yes 2>&1)
ssh_exit_code=$?

echo "Résultat de la connexion :"
echo "$ssh_result"

if echo "$ssh_result" | grep -q "logged in as"; then
    echo "✅ Connexion SSH à Bitbucket réussie !"
    username=$(echo "$ssh_result" | grep "logged in as" | sed 's/.*logged in as \(.*\)\./\1/')
    echo "👤 Connecté en tant que : $username"
elif echo "$ssh_result" | grep -q "Permission denied"; then
    echo "❌ Permission refusée - clé SSH non autorisée"
    echo "💡 Ajoutez votre clé publique à Bitbucket :"
    echo "   https://bitbucket.org/account/settings/ssh-keys/"
elif echo "$ssh_result" | grep -q "Host key verification failed"; then
    echo "❌ Vérification de l'hôte échouée"
    echo "💡 Ajoutez Bitbucket aux hosts connus :"
    echo "   ssh-keyscan bitbucket.org >> ~/.ssh/known_hosts"
else
    echo "❌ Connexion SSH échouée (code: $ssh_exit_code)"
    echo "💡 Vérifiez votre configuration SSH"
fi

# 3. Test d'accès aux repositories
echo ""
echo "📦 Test d'accès aux repositories..."

test_repo() {
    local repo_url="$1"
    local repo_name="$2"

    echo -n "📋 Test $repo_name ($repo_url)... "
    if git ls-remote --heads "$repo_url" >/dev/null 2>&1; then
        echo "✅ Accès OK"
    else
        echo "❌ Accès échoué"
    fi
}

test_repo "git@bitbucket.org:pcafxc/mason.git" "Mason"
test_repo "git@bitbucket.org:pcafxc/painter.git" "Painter"
test_repo "git@bitbucket.org:pcafxc/gestioncarte.git" "GestionCarte"

# 4. Instructions de correction
echo ""
echo "💡 Instructions de correction :"
echo "==============================="

if echo "$ssh_result" | grep -q "logged in as"; then
    echo "✅ SSH fonctionne ! Vous pouvez maintenant configurer Docker :"
    echo "   ./setup_ssh_docker.sh"
else
    echo "❌ SSH ne fonctionne pas. Actions requises :"
    echo ""
    echo "1️⃣ Vérifiez que votre clé publique est ajoutée à Bitbucket :"
    echo "   • Allez sur https://bitbucket.org/account/settings/ssh-keys/"
    echo "   • Ajoutez le contenu de ~/.ssh/bitbucket_ed25519.pub"
    echo ""
    echo "2️⃣ Si pas de clé SSH ED25519, générez-en une :"
    echo "   ssh-keygen -t ed25519 -f ~/.ssh/bitbucket_ed25519 -C 'votre-email@exemple.com'"
    echo ""
    echo "3️⃣ Configurez SSH pour utiliser cette clé pour Bitbucket :"
    echo "   echo 'Host bitbucket.org' >> ~/.ssh/config"
    echo "   echo '  IdentityFile ~/.ssh/bitbucket_ed25519' >> ~/.ssh/config"
    echo ""
    echo "4️⃣ Ajoutez Bitbucket aux hosts connus :"
    echo "   ssh-keyscan bitbucket.org >> ~/.ssh/known_hosts"
    echo ""
    echo "5️⃣ Testez à nouveau :"
    echo "   ssh -i ~/.ssh/bitbucket_ed25519 -T git@bitbucket.org"
fi