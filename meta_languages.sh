#!/bin/bash
# 動作環境
# * LinuxMint17.3MATE
# * SQLite3
# * jq
# 事前定義が必要な変数
# * USER_NAME
# * DB_REPO
# * HDR_TIMEZONE
# * HDR_AUTHOR
# * USER_NAME

# リポジトリにあるソースコードのプログラミング言語とByte数を取得する。
# $1: RepositoryName 
function RegistLanguages() {
	local SQL="SELECT Id FROM Repositories WHERE Name='${REPO_NAME}' LIMIT 1;"
	local COMMAND="sqlite3 ${DB_REPO}"
	local REPO_ID=`echo $SQL | $COMMAND`
	[ "" = "${REPO_ID}" ] && (echo "リポジトリ'${REPO_NAME}'がDBにありません。登録してから再度実行してください。"; exit;)
	local JSON_FILE="GitHub.${USER_NAME}.${REPO_NAME}.Languages.json"
	#local HDR_TIMEZONE="Time-Zone: Asia/Tokyo"
	#local HDR_AUTHOR="Authorization: token ${TOKEN}"
	curl -k  -o "${JSON_FILE}" -H "${HDR_TIMEZONE}" -H "${HDR_AUTHOR}" https://api.github.com/repos/${USER_NAME}/${REPO_NAME}/languages
	sleep 2s

	# 既存レコードを削除
	SQL="DELETE FROM Languages WHERE RepositoryId=${REPO_ID};"
	COMMAND="sqlite3 ${DB_REPO}"
	echo $SQL | $COMMAND

	# 新規レコードを追加
	for LANG_NAME in `cat ${JSON_FILE} | jq -r keys[]`
	do
		local LANG_SIZE=`cat ${JSON_FILE} | jq .${LANG_NAME}`
		SQL="INSERT INTO Languages(RepositoryId,Language,Size) VALUES(${REPO_ID},'${LANG_NAME}',${LANG_SIZE});"
		COMMAND="sqlite3 ${DB_REPO}"
		echo $SQL | $COMMAND
	done
}

