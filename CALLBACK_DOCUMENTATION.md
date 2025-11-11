# Documentation du Système de Callback Ambitions v2.0

## Vue d'ensemble

Le système de callback Ambitions est une solution complètement refactorisée pour la communication asynchrone bidirectionnelle entre client et serveur. Il offre une API claire avec `.register()` et `.trigger()`, une gestion avancée des ressources, et des protections contre les abus.

## Architecture Refactorisée

### Structure modulaire
```
shared/lib/callback.lua    # Registry partagé avec statistiques avancées
client/lib/callback.lua    # API client avec rate limiting et concurrence
server/lib/callback.lua    # API serveur avec validation de joueurs
```

### Nouveaux principes

1. **Registry Centralisé** : Gestion unifiée des callbacks avec statistiques
2. **API Explicite** : `.register()` pour enregistrer, `.trigger()` pour appeler
3. **Protection Avancée** : Rate limiting, validation, limites de concurrence
4. **Monitoring** : Statistiques détaillées et nettoyage automatique

## Système de Validation Avancé

### Protections intégrées :
- **Conflits de noms** : Prévention des écrasements entre ressources
- **Rate limiting** : Protection contre le spam de callbacks
- **Validation de joueurs** : Vérification existence + ping côté serveur
- **Limites de concurrence** : Max 50 appels simultanés client, 25 par joueur serveur

### Événements réseau :
- `ambitions:callback:validate` : Validation centralisée
- `ambitions:callback:server:call` : Appels serveur
- `ambitions:callback:client:call` : Appels client
- `ambitions:callback:response:[resource]` : Réponses par ressource

## Communication Bidirectionnelle

Le système de callback Ambitions supporte **4 scénarios** de communication :

### 🔄 Scénario 1 : Client appelle Serveur (le plus commun)
```lua
-- SERVEUR : Enregistre le callback
local callback = require('server.lib.callback')
callback.register('ambitions:getPlayerMoney', function(source, accountType)
    return GetPlayerMoney(source, accountType or 'bank')
end)

-- CLIENT : Trigger le callback serveur avec nouvelle API
local callback = require('client.lib.callback')
callback.trigger('ambitions:getPlayerMoney', false, function(money)
    print('Mon argent:', money)
end, 'bank')
```

### 🔄 Scénario 2 : Serveur appelle Client (moins commun mais très utile)
```lua
-- CLIENT : Enregistre le callback
local callback = require('client.lib.callback')
callback.register('ambitions:getPlayerPosition', function()
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    return { x = coords.x, y = coords.y, z = coords.z }
end)

-- SERVEUR : Trigger le callback client avec nouvelle API
local callback = require('server.lib.callback')
callback.trigger('ambitions:getPlayerPosition', playerId, false, function(coords)
    print('Joueur à la position:', coords.x, coords.y, coords.z)
    -- Utiliser la position pour téléporter, spawn, etc.
end)
```

## Côté Serveur - Guide Complet v2.0

### Import
```lua
local callback = require('server.lib.callback')
```

### ➡️ Enregistrer des callbacks serveur (avec callback.register)
```lua
-- Callback simple qui retourne des données
callback.register('ambitions:getPlayerMoney', function(source, accountType)
    -- source = ID du joueur automatiquement fourni
    -- accountType = paramètre envoyé par le client
    
    local money = GetPlayerMoney(source, accountType or 'bank')
    return money -- Retour automatique au client
end)

-- Callback avec validation et sécurité avancée
callback.register('ambitions:buyItem', function(source, itemName, quantity)
    local player = GetPlayer(source)
    if not player then return false, 'Player not found' end
    
    local price = GetItemPrice(itemName) * quantity
    if player.money < price then
        return false, 'Insufficient funds'
    end
    
    player:removeMoney(price)
    player:addItem(itemName, quantity)
    return true, player.money, 'Item purchased successfully'
end)

-- Callback avec gestion d'erreurs intégrée
callback.register('ambitions:saveCharacter', function(source, characterData)
    local success, err = pcall(SaveCharacterData, source, characterData)
    return success, err
end)
```

### ⬅️ Trigger des callbacks client (avec callback.trigger)
```lua
-- Demander la position d'un joueur (syntax simplifiée)
callback.trigger('ambitions:getPlayerPosition', playerId, false, function(coords)
    if coords then
        print('Joueur', playerId, 'est à:', coords.x, coords.y, coords.z)
        -- Utiliser les coordonnées pour la logique serveur
    end
end)

-- Demander confirmation avec options avancées
callback.trigger('ambitions:confirmAction', playerId, {timeout = 30000}, function(confirmed)
    if confirmed then
        -- Exécuter l'action
        GiveReward(playerId)
    else
        -- Action annulée ou timeout
        log.info('Action cancelled or timed out for player', playerId)
    end
end, 'Voulez-vous recevoir votre récompense ?', 'question')

-- Appel avec validation automatique de joueur
callback.trigger('ambitions:getUIData', playerId, false, function(uiData)
    if uiData then
        -- Le système valide automatiquement que le joueur existe
        ProcessUIData(playerId, uiData)
    end
end)
```

## Côté Client - Guide Complet v2.0

### Import
```lua
local callback = require('client.lib.callback')
```

### ➡️ Enregistrer des callbacks client (avec callback.register)
```lua
-- Callback qui retourne la position du joueur
callback.register('ambitions:getPlayerPosition', function()
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    return { x = coords.x, y = coords.y, z = coords.z }
end)

-- Callback pour afficher une confirmation avec validation
callback.register('ambitions:confirmAction', function(message, type)
    -- Afficher une UI de confirmation avec timeout
    local result = ShowConfirmDialog(message, type, 15000) -- 15s timeout
    return result -- true/false selon le choix du joueur
end)

-- Callback pour récupérer des données d'interface optimisé
callback.register('ambitions:getUIData', function()
    local playerPed = PlayerPedId()
    local uiData = {
        selectedWeapon = GetSelectedPedWeapon(playerPed),
        health = GetEntityHealth(playerPed),
        armor = GetPedArmour(playerPed),
        vehicle = GetVehiclePedIsIn(playerPed, false),
        timestamp = GetGameTimer()
    }
    return uiData
end)

-- Callback pour traiter des actions côté client avec sécurité
callback.register('ambitions:processClientAction', function(actionType, actionData)
    local playerPed = PlayerPedId()
    
    if actionType == 'teleport' then
        if actionData.x and actionData.y and actionData.z then
            SetEntityCoords(playerPed, actionData.x, actionData.y, actionData.z)
            return true
        end
    elseif actionType == 'give_weapon' then
        if actionData.weapon and actionData.ammo then
            GiveWeaponToPed(playerPed, actionData.weapon, actionData.ammo, false, false)
            return true
        end
    end
    return false, 'Invalid action or data'
end)
```

### ⬅️ Trigger des callbacks serveur (avec callback.trigger)
```lua
-- Demander son argent avec nouvelle API
callback.trigger('ambitions:getPlayerMoney', false, function(money)
    print('Mon argent:', money)
    UpdateMoneyDisplay(money)
end, 'bank')

-- Acheter un item avec délai anti-spam et options avancées
callback.trigger('ambitions:buyItem', {delay = 1000, timeout = 10000}, function(success, newBalance, message)
    if success then
        ShowNotification('✅ ' .. message, 'success')
        UpdateMoneyDisplay(newBalance)
    else
        ShowNotification('❌ ' .. (message or 'Purchase failed'), 'error')
    end
end, 'weapon_pistol', 1)

-- Sauvegarder des données avec gestion d'erreur améliorée
callback.trigger('ambitions:saveCharacter', false, function(success, errorMsg)
    if success then
        ShowNotification('Personnage sauvegardé', 'success')
    else
        ShowNotification('Erreur: ' .. (errorMsg or 'Unknown error'), 'error')
    end
end, GetCharacterData())
```

## Fonctionnalités Avancées

### Gestion des timeouts
```lua
-- Timeout par défaut : 5 minutes (300000ms)
-- Configurable via convar: ambitions:callbackTimeout

-- Si un callback ne répond pas dans le délai:
-- Côté client: log.warning avec message de timeout
-- Côté serveur: log.warning avec message de timeout incluant player ID
```

### Délais anti-spam
```lua
-- Empêche d'appeler le même callback trop rapidement
callback('ambitions:spamProtected', 2000, function(result) -- 2 secondes de délai
    print('Résultat:', result)
end)

-- Si appelé trop tôt, la fonction return immédiatement sans faire l'appel
```

### Clés uniques
```lua
-- Le système génère des clés alphanumériques uniques:
-- Format client: 'eventName:A7B3C9D1'  
-- Format serveur: 'eventName:F2H8K5M9:playerId'

-- Utilise ambitionsRandom.alphanumeric(8) pour 62^8 combinaisons possibles
-- Évite les collisions même avec beaucoup de callbacks simultanés
```

## Gestion d'erreurs

### Callbacks inexistants
```lua
-- Si le callback n'existe pas:
-- - Message d'erreur dans les logs
-- - 'cb_invalid' est envoyé en réponse
-- - Pas de crash du système
```

### Validation des paramètres
```lua
-- Le système valide automatiquement:
-- - Type de la fonction callback
-- - Existence du joueur (côté serveur)
-- - Format des événements
```

### Nettoyage automatique
```lua
-- Quand une ressource s'arrête:
-- - Tous ses callbacks sont supprimés du registre
-- - Les callbacks en cours sont annulés
-- - Logs de nettoyage générés
```

## Exemples Complets

### Système d'inventaire
```lua
-- SERVEUR
callback.register('ambitions:getInventory', function(source)
    local player = GetPlayer(source)
    return player and player.inventory or {}
end)

callback.register('ambitions:useItem', function(source, itemName, amount)
    local player = GetPlayer(source)
    local success = player:useItem(itemName, amount)
    return success, player:getItemCount(itemName)
end)

-- CLIENT
callback.register('ambitions:showInventoryUI', function()
    -- Récupérer l'inventaire du serveur
    callback('ambitions:getInventory', false, function(inventory)
        OpenInventoryUI(inventory)
    end)
    return true
end)

-- Utiliser un item
function UseItem(itemName, amount)
    callback('ambitions:useItem', false, function(success, remainingCount)
        if success then
            UpdateInventoryUI(itemName, remainingCount)
        else
            ShowNotification('Impossible d\'utiliser cet item')
        end
    end, itemName, amount)
end
```

### Système de notification
```lua
-- SERVEUR
-- Envoyer notification à un joueur
function NotifyPlayer(playerId, message, type)
    callback('ambitions:showNotification', playerId, function(seen)
        if seen then
            log.debug('Notification vue par', playerId)
        end
    end, message, type)
end

-- CLIENT
callback.register('ambitions:showNotification', function(message, type)
    ShowNotification(message, type or 'info')
    -- Retourner true pour confirmer que la notification a été vue
    return true
end)
```

## Bonnes Pratiques

### Nommage des callbacks
```lua
-- Utilisez le préfixe de votre ressource
'ambitions:getPlayerData'
'inventory:addItem' 
'shop:buyItem'

-- Soyez descriptifs
'ambitions:getPlayerVehicles' ✓
'ambitions:getVeh' ✗
```

### Gestion des erreurs
```lua
-- Toujours vérifier les retours
callback('ambitions:getData', false, function(data)
    if data then
        -- Utiliser les données
    else
        -- Gérer l'erreur
    end
end)

-- Dans les callbacks, retourner nil en cas d'erreur
callback.register('ambitions:getData', function(source)
    local data = GetPlayerData(source)
    return data -- nil si erreur, data sinon
end)
```

### Performance
```lua
-- Utiliser les délais pour éviter le spam
callback('expensive:operation', 5000, handler) -- 5 secondes

-- Éviter les callbacks dans les boucles
for i = 1, 100 do
    callback('bad:idea', false, handler) -- ✗ Mauvais
end

-- Plutôt:
local batch = {}
for i = 1, 100 do
    table.insert(batch, data[i])
end
callback('good:batchOperation', false, handler, batch) -- ✓ Bon
```

## Dépannage

### Callback ne répond pas
1. Vérifier que le callback est bien enregistré
2. Vérifier les logs pour les erreurs
3. Vérifier le timeout (5 min par défaut)

### Conflits de noms
1. Utiliser des préfixes uniques par ressource
2. Vérifier les logs de validation au démarrage

### Performances lentes
1. Éviter les callbacks dans les boucles
2. Utiliser les délais anti-spam
3. Grouper les opérations en batch quand possible

## Configuration

### Convars disponibles
```
# Timeout des callbacks en millisecondes (défaut: 300000 = 5 minutes)
set ambitions:callbackTimeout 180000
```