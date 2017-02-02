#!/bin/bash
# 動作環境
# * LinuxMint17.3MATE
# * SQLite3
# * jq
# 引数一覧
# * ユーザ名
# * SSH_HOST名
# * DBファイルパス
# * リポジトリ説明
# * リポジトリURL
# * commitメッセージ
# DBから取得するデータ
# * MailAddress
# * AccessToken

USER_NAME=ytyaru0
SSH_HOST=github.com.${USER_NAME}
DB_ACCOUNTS="/media/mint/B2701BBB701B84EF/root/db/Account/GitHub/private/v0/GitHub.Accounts.sqlite3"
DB_REPO="/media/mint/B2701BBB701B84EF/root/db/Account/GitHub/public/v0/GitHub.Repositories.${USER_NAME}.sqlite3"
REPO_DESC=GitHubリポジトリを作成してローカルDBに登録するシェルスクリプト。
REPO_HOME=http://ytyaru.hatenablog.com/entry/2017/03/21/000000

# メアド取得
SQL="SELECT MailAddress FROM Accounts WHERE Username='${USER_NAME}';"
COMMAND="sqlite3 ${DB_ACCOUNTS}"
USER_MAIL=`echo $SQL | $COMMAND`
#[ "" = "${USER_MAIL}" ] && (echo "メールアドレスがDBにありません。登録してから再度実行してください。"; exit;)
# AccessToken取得
SQL="SELECT Id FROM Accounts WHERE Username='${USER_NAME}';"
ACC_ID=`echo $SQL | $COMMAND`
SQL="SELECT AccessToken FROM AccessTokens WHERE AccountId='${ACC_ID}' AND (',' || Scopes || ',') LIKE '%,repo,%' LIMIT 1;"
TOKEN=`echo $SQL | $COMMAND`
#[ "" = "${TOKEN}" ] && (echo "AccessTokenがDBにありません。Scopesに'repo'がある'${USER_NAME}'ユーザのTokenを登録してから再度実行してください。"; exit;)

# 共通HTTPヘッダ
HDR_TIMEZONE="Time-Zone: Asia/Tokyo"
HDR_AUTHOR="Authorization: token ${TOKEN}"

# リポジトリ名を取得（親ディレクトリ名）
REPO_NAME=`basename $(cd $(dirname $0) && pwd)`

# .gitディレクトリ存在確認
if [ ! -e "./.git" ]; then
	answer=
	while [ "" = "${answer}" ]
	do
		echo USER: ${USER_NAME}
		echo MAIL: ${USER_MAIL}
		echo SSH_HOST: ${SSH_HOST}
		echo リポジトリ名：${REPO_NAME}
		echo 説明：${REPO_DESC}
		echo URL：${REPO_HOME}
		echo "リポジトリ情報は上記のとおりで間違いありませんか？[y/n]"
		read answer
		if [ "y" = "${answer}" ] || [ "Y" = "${answer}" ]; then
			echo .gitを作成します
			git init
			# アカウント情報をセットする
			git config --local user.name "${USER_NAME}"
			git config --local user.email "${USER_MAIL}"
			git remote add origin git@${SSH_HOST}:${USER_NAME}/${REPO_NAME}.git
			# リモートリポジトリを作成する
			POST_DATA='{"name":"'${REPO_NAME}'","description":"'${REPO_DESC}'","homepage":"'${REPO_HOME}'"}'
			echo ${POST_DATA}
			HDR_TIMEZONE="Time-Zone: Asia/Tokyo"
			HDR_AUTHOR="Authorization: token ${TOKEN}"
			JSON_FILE="GitHub.${USER_NAME}.${REPO_NAME}.json"
			curl -k  -o "${JSON_FILE}" -H "${HDR_TIMEZONE}" -H "${HDR_AUTHOR}" https://api.github.com/user/repos -d "${POST_DATA}"
			sleep 5s
			# DBにリモートリポジトリ情報を登録する
			. meta_insert.sh
			echo `ResistRepository`
#			REPO_ID=$(ResistRepository ${USER_NAME})
#			REPO_ID=$(ResistRepository)
#			echo RepoId=${REPO_ID}
		elif [ "n" = "${answer}" ] || [ "N" = "${answer}" ]; then
			echo 編集してから再度実行してください。
			exit
		else
			answer=
			clear
		fi
	done
fi

# 実行確認
echo リポジトリ名：${USER_NAME}/${REPO_NAME}
echo 説明：${REPO_DESC}
echo URL：${REPO_HOME}
echo ----------------------------------------
git add -n .
echo commit,pushするならメッセージを入力してください。Enterかnで終了します。
echo サブコマンド    n:終了 e:編集 d:削除 i:Issue作成
read answer
if [ "" = "${answer}" ] || [ "n" = "${answer}" ] || [ "N" = "${answer}" ]; then
	echo 何もせず終了します。
elif [ "e" = "${answer}" ] || [ "E" = "${answer}" ]; then
	echo リポジトリ編集します。（未実装）
elif [ "d" = "${answer}" ] || [ "D" = "${answer}" ]; then
	echo リポジトリ削除します。（未実装）
elif [ "i" = "${answer}" ] || [ "I" = "${answer}" ]; then
	echo Issue作成します。（未実装）
else
	echo commitします。[${answer}]
	git add .
	git commit -m "${answer}"
	git push origin master
	# 言語とByteを取得しDBへ挿入する
	sleep 5s
	. meta_languages.sh
	echo `RegistLanguages`
fi

