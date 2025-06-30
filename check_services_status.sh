#!/bin/bash

echo "📊 Vérification du statut des services CardManager"
echo "=================================================="

# 1. Statut des conteneurs
echo "🐳 Statut des conteneurs Docker :"
docker-compose ps

echo ""
echo "📋 Détail des services :"
echo "========================"

# 2. Test MariaDB
echo "🗄️ MariaDB :"
if docker-compose exec cardmanager-mariadb mariadb-admin ping -h localhost -u root -pfoufafou >/dev/null 2>&1; then
    echo "   ✅ MariaDB fonctionne"

    # Test de connexion utilisateur
    if docker-compose exec cardmanager-mariadb mariadb -u ia -pfoufafou -e "USE dev; SELECT COUNT(*) as table_count FROM information_schema.tables WHERE table_schema='dev';" 2>/dev/null; then
        echo "   ✅ Base de données 'dev' accessible"
    else
        echo "   ⚠️ Problème d'accès à la base 'dev'"
    fi
else
    echo "   ❌ MariaDB ne répond pas"
fi

# 3. Test Painter
echo ""
echo "🎨 Painter :"
if docker-compose ps painter | grep -q "Up"; then
    echo "   ✅ Conteneur Painter en cours d'exécution"

    # Test health check
    if docker-compose exec painter curl -f http://localhost:8081/actuator/health >/dev/null 2>&1; then
        echo "   ✅ Painter répond au health check"

        # Test API
        painter_health=$(docker-compose exec painter curl -s http://localhost:8081/actuator/health 2>/dev/null || echo "ERROR")
        if echo "$painter_health" | grep -q "UP"; then
            echo "   ✅ API Painter fonctionnelle"
        else
            echo "   ⚠️ API Painter en cours de démarrage"
        fi
    else
        echo "   ⚠️ Painter ne répond pas encore au health check"
    fi

    # Vérifier les logs récents
    echo "   📋 Derniers logs Painter :"
    docker-compose logs --tail=3 painter | grep -E "(Started|ERROR|WARN)" | tail -3
else
    echo "   ❌ Conteneur Painter non démarré"
fi

# 4. Test GestionCarte
echo ""
echo "💳 GestionCarte :"
if docker-compose ps gestioncarte | grep -q "Up"; then
    echo "   ✅ Conteneur GestionCarte en cours d'exécution"

    # Test health check
    if docker-compose exec gestioncarte curl -f http://localhost:8080/actuator/health >/dev/null 2>&1; then
        echo "   ✅ GestionCarte répond au health check"
    else
        echo "   ⚠️ GestionCarte ne répond pas encore au health check"
    fi
else
    echo "   ❌ Conteneur GestionCarte non démarré"
fi

# 5. Test des ports externes
echo ""
echo "🌐 Tests d'accès externes :"
echo "=========================="

# Test MariaDB externe
echo -n "🗄️ MariaDB (localhost:3307): "
if nc -z localhost 3307 2>/dev/null; then
    echo "✅ Accessible"
else
    echo "❌ Non accessible"
fi

# Test Painter externe
echo -n "🎨 Painter (localhost:8081): "
if nc -z localhost 8081 2>/dev/null; then
    echo "✅ Port ouvert"

    # Test HTTP
    if curl -f http://localhost:8081/actuator/health >/dev/null 2>&1; then
        echo "   ✅ HTTP fonctionne"
    else
        echo "   ⚠️ HTTP en cours de démarrage"
    fi
else
    echo "❌ Port fermé"
fi

# Test GestionCarte externe
echo -n "💳 GestionCarte (localhost:8080): "
if nc -z localhost 8080 2>/dev/null; then
    echo "✅ Port ouvert"

    # Test HTTP
    if curl -f http://localhost:8080/actuator/health >/dev/null 2>&1; then
        echo "   ✅ HTTP fonctionne"
    else
        echo "   ⚠️ HTTP en cours de démarrage"
    fi
else
    echo "❌ Port fermé"
fi

# 6. Résumé
echo ""
echo "🎯 Résumé de l'état :"
echo "===================="

mariadb_ok=$(docker-compose ps cardmanager-mariadb | grep -q "Up" && echo "✅" || echo "❌")
painter_ok=$(docker-compose ps cardmanager-painter | grep -q "Up" && echo "✅" || echo "❌")
gestioncarte_ok=$(docker-compose ps cardmanager-gestioncarte | grep -q "Up" && echo "✅" || echo "❌")

echo "🗄️ MariaDB: $mariadb_ok"
echo "🎨 Painter: $painter_ok"
echo "💳 GestionCarte: $gestioncarte_ok"

if [[ "$mariadb_ok" == "✅" && "$painter_ok" == "✅" ]]; then
    echo ""
    echo "🎉 SUCCÈS ! Le système CardManager fonctionne !"
    echo "🌐 URLs disponibles :"
    echo "   • Painter: http://localhost:8081"
    echo "   • GestionCarte: http://localhost:8080 (si démarré)"
    echo "   • MariaDB: localhost:3307"
elif [[ "$painter_ok" == "✅" ]]; then
    echo ""
    echo "🎊 SUCCÈS PARTIEL ! Painter fonctionne parfaitement !"
    echo "🌐 Painter disponible : http://localhost:8081"
    echo "💡 Pour démarrer GestionCarte :"
    echo "   docker-compose up -d gestioncarte"
else
    echo ""
    echo "⚠️ Certains services nécessitent encore de l'attention"
    echo "💡 Commandes utiles :"
    echo "   • Logs : docker-compose logs [service]"
    echo "   • Restart : docker-compose restart [service]"
fi