#!/usr/bin/env bash
# find files newer than previous backup and send it by mail
# backup file is splitted and encripted.
# you can use 'cat' command to concatenate,
# and 'openssl enc -d -aes256 -k $ENC_PASSWORD' to decrypt it.
 
# this script uses  'mutt' command and 'msmtp' as sendmail client

# you may use this script with ./periodic_mysqldump.sh
# for example, you can add following jobs to crontab
# 0 3 * * 1 /path/to/kagetra/scripts/with_rbenv.sh ./periodic_mysqldump.sh
# 0 4 * * 1 /path/to/kagetra/scripts/with_rbenv.sh ./send_backup_as_emal.sh

MAIL_ADDR="${CONF_BKUP_MAIL_TO}" # mail address to send backup files
MAIL_BODY="${CONF_BKUP_MAIL_BODY}"
MAIL_SUBJECT="${CONF_BKUP_MAIL_SUBJECT}"
ENC_PASSWORD="${CONF_BKUP_MAIL_ENC_PASSWORD}"
SPLIT_SIZE="${CONF_BKUP_MAIL_SPLIT_SIZE}" # backup files will be splitted in this size

# basic settings
CURDIR="$(dirname $(readlink -f $0))"
WORKDIR="${CURDIR}/../${CONF_BKUP_WORKDIR}"
BKUP_ROOT="${CURDIR}/../"
NEXT_BKUP_FROM="${WORKDIR}/next_bkup_from"
MSMTP_CONFIG="${WORKDIR}/msmtprc"

function my_send_mail(){
  echo "$MAIL_BODY" | mutt -e 'set copy=no; set sendmail="/usr/bin/msmtp -C '"$MSMTP_CONFIG"'"' -s "$MAIL_SUBJECT" -a "$1" -- "$2"
}

function create_msmtprc(){
  cat >"$MSMTP_CONFIG" <<HEREDOC
defaults
auth on
tls on
tls_trust_file ${CONF_BACKUP_SMTP_TLS_TRUST_FILE}
logfile ${CONF_BACKUP_SMTP_LOGFILE}

account kagetra
host ${CONF_BACKUP_SMTP_HOST}
port ${CONF_BACKUP_SMTP_PORT}
from ${CONF_BACKUP_SMTP_FROM}
user ${CONF_BACKUP_SMTP_USER}
password ${CONF_BACKUP_SMTP_PASSWORD}

account default: kagetra
HEREDOC
}

if [ ! -e "$WORKDIR" ];then
  mkdir -p "$WORKDIR"
fi

if [ ! -e "$NEXT_BKUP_FROM" ];then
  echo "File not found: $NEXT_BKUP_FROM."
  echo "Maybe this is the first time you executed this command."
  echo "Mou must create it by executing:"
  echo '$ date -d "7 days ago" +"%F %H:%M:%S" > '$NEXT_BKUP_FROM
  exit 0
fi
next_bkup_time="$(date -d '30 minutes ago' +'%F %H:%M:%S')"
cd "$BKUP_ROOT"
prefix="kagetra-bkup-$(date +'%F-%H%M%S')".tgz.enc.

find "${CONF_STORAGE_DIR}" "${CONF_DUMP_DIR}" \
-type f -newermt "$(cat $NEXT_BKUP_FROM)" -print0 | \
tar zcv --null -T- | \
openssl enc -e -aes256 -k $ENC_PASSWORD | \
split - $WORKDIR/$prefix -a 3 -b $SPLIT_SIZE -d
create_msmtprc
for f in $WORKDIR/kagetra-bkup-*; do
  echo -n "sending $f to $MAIL_ADDR .."
  my_send_mail "$f" "$MAIL_ADDR"
  if [ $? -eq 0 ];then
    rm -f "$f"
  else
    echo "sending mail failed, so we break the loop"
    break
  fi
  echo "done"
  echo -n "sleeping 10 seconds.."
  sleep 10 # maybe some smtp server hates sending a lot of file in once.
  echo "done"
done
echo "$next_bkup_time" > "$NEXT_BKUP_FROM"
