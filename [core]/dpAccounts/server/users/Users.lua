Users = {}
local USERS_TABLE_NAME = "users"
local PASSWORD_SECRET = "s9abBUIg090j21aASGzc90avj1l"

function Users.setup()
	DatabaseTable.create(USERS_TABLE_NAME, {
		{ name="username", type="varchar", size=25, options="UNIQUE NOT NULL" },
		{ name="password", type="varchar", size=255, options="NOT NULL" },
		{ name="online", type="bool", options="DEFAULT 0" },
		{ name="money", type="bigint", options="UNSIGNED NOT NULL DEFAULT 0" },
		{ name="skin", type="smallint", options="UNSIGNED NOT NULL DEFAULT 0" },
		{ name="lastseen", type="timestamp", options="NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP" }
	}, function (result)
		if not result then
			outputDebugString("Users table already exists")
		end
	end)
	-- Очистка информации о входе
	DatabaseTable.update(USERS_TABLE_NAME, {online=0}, {})
	-- Очистка даты
	for i, player in ipairs(getElementsByType("player")) do
		PlayerData.clear(player)
	end
end

-- Функция хэширования паролей пользователей
local function hashUserPassword(username, password)
	return sha256(password .. tostring(username) .. tostring(string.len(username)) .. tostring(PASSWORD_SECRET))
end

-- Проверка пароля, повторного входа и т. д.
local function verifyLogin(player, username, password, account)
	if	not exports.dpUtils:argcheck(player, "player") or
		not exports.dpUtils:argcheck(username, "string") or
		not exports.dpUtils:argcheck(password, "string") or
		not exports.dpUtils:argcheck(account, "table")
	then
		exports.dpLog:error("verifyLogin: User not found")
		return false, "user_not_found"
	end
	-- Проверка двойного входа
	if tonumber(account.online) == 1 then
		exports.dpLog:error("verifyLogin: User already logged in")
		return false, "already_logged_in"
	end
	-- Проверка правильности пароля
	password = hashUserPassword(username, password)
	if password ~= account.password then
		exports.dpLog:error("verifyLogin: Incorrect password")
		return false, "incorrect_password"
	end
	return true
end

function Users.registerPlayer(player, username, password, callback)
	if 	not exports.dpUtils:argcheck(player, "player") or
		not exports.dpUtils:argcheck(username, "string") or 
		not exports.dpUtils:argcheck(password, "string")
	then	
		exports.dpLog:error("Users.registerPlayer: bad arguments")
		return false
	end
	username = string.lower(username)
	-- Проверка имени пользователя и пароля
	if not checkUsername(username) or not checkPassword(password) then
		exports.dpLog:error("Users.registerPlayer: bad username or password")
		return false, "bad_password"
	end
	-- Хэширование пароля
	password = hashUserPassword(username, password)
	-- Добавление пользователя в базу
	DatabaseTable.insert(USERS_TABLE_NAME, {
		username = username,
		password = password
	}, callback)
	return true
end

function Users.loginPlayer(player, username, password, callback)
	if 	not exports.dpUtils:argcheck(player, "player") or
		not exports.dpUtils:argcheck(username, "string") or 
		not exports.dpUtils:argcheck(password, "string")
	then	
		exports.dpLog:error("Users.registerPlayer: bad arguments")
		return false
	end
	username = string.lower(username)

	-- Если игрок уже залогинен
	if Sessions.isActive(player) then
		exports.dpLog:error("Users.loginPlayer: User already logged in")
		return false, "already_logged_in"
	end
	-- Получение пользователя из базы
	return DatabaseTable.select(USERS_TABLE_NAME, {}, { username = username }, function(result)
		local success, errorType = not not result, "user_not_found"
		local account
		-- Проверка пароля и т. д.
		if result then
			account = result[1]
			success, errorType = verifyLogin(player, username, password, account)
		end
		if success then
			-- Запустить сессию
			success = Sessions.start(player)
			if success then					
				DatabaseTable.update(USERS_TABLE_NAME, {online=1}, {username=username})
				PlayerData.set(player, account)
			else
				errorType = "already_logged_in"
			end
		end
		-- Вызывать callback
		if callback and type(callback) == "function" then
			callback(success, errorType)
		end
	end)
end

function Users.isPlayerLoggedIn(player)
	return Sessions.isActive(player)
end

function Users.logoutPlayer(player, callback)
	if not isElement(player) then
		return false
	end
	if not Sessions.isActive(player) then
		return false
	end	
	Users.saveAccount(player)
	Sessions.stop(player)

	local username = player:getData("username")
	return DatabaseTable.update(USERS_TABLE_NAME, {online=0}, {username=username}, function(result)
		if type(callback) == "function" then
			callback(not not result)
		end
	end)
end

function Users.saveAccount(player)
	if not isElement(player) then
		return false
	end
	if not Sessions.isActive(player) then
		return false
	end
	local username = player:getData("username")
	local fields = PlayerData.get(player)
	DatabaseTable.update(USERS_TABLE_NAME, fields, {username=username})
	return true
end

addEvent("dpAccounts.registerRequest", true)
addEventHandler("dpAccounts.registerRequest", resourceRoot, function(username, password)
	local player = client
	local success, errorType = Users.registerPlayer(player, username, password, function(result)
		result = not not result
		local errorType = ""
		if not result then
			errorType = "username_taken"
		end
		triggerClientEvent(player, "dpAccounts.registerResponse", resourceRoot, result, errorType)
		triggerEvent("dpAccounts.register", player, result, errorType)
	end)
	if not success then
		triggerClientEvent(player, "dpAccounts.registerResponse", resourceRoot, false)
		triggerEvent("dpAccounts.register", player, false, errorType)
	end
end)

addEvent("dpAccounts.loginRequest", true)
addEventHandler("dpAccounts.loginRequest", resourceRoot, function(username, password)
	local player = client
	local success, errorType = Users.loginPlayer(player, username, password, function(result, errorType)
		triggerClientEvent(player, "dpAccounts.loginResponse", resourceRoot, result, errorType)
		triggerEvent("dpAccounts.login", player, result, errorType)
	end)
	if not success then
		triggerClientEvent(player, "dpAccounts.loginResponse", resourceRoot, false, errorType)
		triggerEvent("dpAccounts.login", player, false, errorType)
	end
end)

addEvent("dpAccounts.logoutRequest", true)
addEventHandler("dpAccounts.logoutRequest", resourceRoot, function(username, password)
	local player = client
	local success = Users.logoutPlayer(player, function(result)
		triggerClientEvent(player, "dpAccounts.logoutResponse", resourceRoot, result)
		triggerEvent("dpAccounts.logout", player, result)
	end)
	if not success then
		triggerClientEvent(player, "dpAccounts.logoutResponse", resourceRoot, false)
		triggerEvent("dpAccounts.logout", player, false)
	end
end)