#!/bin/bash
# 動作環境
# * LinuxMint17.3MATE
# * SQLite3
# * jq
# 事前定義が必要な変数
# * USER_NAME
# * DB_REPO
# * REPO_NAME
# * HDR_TIMEZONE
# * HDR_AUTHOR
function ResistRepository() {
#	local USER_NAME=$1
#	local DB_REPO="/media/mint/B2701BBB701B84EF/root/db/Account/GitHub/public/v0/GitHub.Repositories.${USER_NAME}.sqlite3"
#	local REPO_NAME=`basename $(cd $(dirname $0) && pwd)`
#	echo ${DB_REPO}
#	echo ${REPO_NAME}

	# JSONファイルから値を取得する
	local JSON_FILE="GitHub.${USER_NAME}.${REPO_NAME}.json"
#	echo ${JSON_FILE}
	local IdOnGitHub=`cat ${JSON_FILE} | jq .id`
	local Name=`cat ${JSON_FILE} | jq -r .name`
	#Description=${REPO_DESC}
	#Homepage=${REPO_HOME}
	local Description=`cat ${JSON_FILE} | jq -r .description`
	local Homepage=`cat ${JSON_FILE} | jq -r .homepage`
	local CreatedAt=`cat ${JSON_FILE} | jq -r .created_at`
	local PushedAt=`cat ${JSON_FILE} | jq -r .pushed_at`
	local UpdatedAt=`cat ${JSON_FILE} | jq -r .updated_at`
	local CheckedAt=`date -u "+%Y-%m-%dT%H:%M:%SZ"`
#	echo ${IdOnGitHub}
#	echo ${Name}
#	echo ${Description}
#	echo ${Homepage}
#	echo ${CreatedAt}
#	echo ${PushedAt}
#	echo ${UpdatedAt}
#	echo ${CheckedAt}
	local Forks=`cat ${JSON_FILE} | jq .forks_count`
	local Stargazers=`cat ${JSON_FILE} | jq .stargazers_count`
	local Watchers=`cat ${JSON_FILE} | jq .watchers_count`
	local Issues=`cat ${JSON_FILE} | jq .open_issues_count`
#	echo ${Forks}
#	echo ${Stargazers}
#	echo ${Watchers}
#	echo ${Issues}
	## DB挿入
	### Repositories
	local SQL="INSERT INTO Repositories(IdOnGitHub,Name,Description,Homepage,CreatedAt,PushedAt,UpdatedAt,CheckedAt) VALUES(${IdOnGitHub},'${Name}','${Description}','${Homepage}','${CreatedAt}','${PushedAt}','${UpdatedAt}','${CheckedAt}');"
	local COMMAND="sqlite3 ${DB_REPO}"
	echo $SQL | $COMMAND
	### Counts
	local SQL="SELECT Id FROM Repositories WHERE IdOnGitHub=${IdOnGitHub};"
	local REPO_ID=`echo $SQL | $COMMAND`
	local SQL="INSERT INTO Counts(RepositoryId,Forks,Stargazers,Watchers,Issues) VALUES(${REPO_ID},${Forks},${Stargazers},${Watchers},${Issues});"
	local COMMAND="sqlite3 ${DB_REPO}"
	echo $SQL | $COMMAND
	# 戻り値
	echo ${REPO_ID}
}
