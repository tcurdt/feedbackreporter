#!/bin/bash
# email handling based on http://grimthing.com/archives/2004/09/18/bash-email-script-with-attachment/
# requires the sharutils (uuencode) to be installed

DIR=/home/tcurdt/feedback
EMAIL_FROM=noreply@vafer.org
EMAIL_TO=tcurdt@vafer.org
EMAIL_SUBJECT="[FeedbackReporter] TYPE for PROJECT"
SHOW_URL=http://vafer.org/feedback/show.php

# do not touch below

function email
{
    from="$1"
    to="$2"
    replyto="$3"
    subject="$4"
    content="$5"
    attachment="$6"

    msgdate=`date +"%a, %e %Y %T %z"` 
    boundary=GvXjxJ+pjyke8COw 
    archdate=`date +%F`
    attachmentbase=`basename "$attachment"`
    archattachment="${archdate}-${attachmentbase}"
    mimetype=`file -i $attachment | awk '{ print $2 }'`

    daemail=$(cat <<!
Date: $msgdate
From: $from
To: $to
Reply-To: $replyto
Subject: $subject
Mime-Version: 1.0
Content-Type: multipart/mixed; boundary="$boundary"
Content-Disposition: inline

--$boundary
Content-Type: text/plain; charset=us-ascii
Content-Disposition: inline

$content

--$boundary
Content-Type: $mimetype;name="$attachmentbase"
Content-Transfer-Encoding: base64
Content-Disposition: attachment;filename="$attachmentbase"
!)

    echo "$daemail"
    echo

    uuencode -m $attachment $attachmentbase | sed '1d' | sed 's/====//'

    echo -e "\n--$boundary--"
}


TIMESTAMP="$DIR/.timestamp"

if [ -f $TIMESTAMP ]; then
    NEWER="-newer $TIMESTAMP"
fi

SUBMISSIONS=`find $DIR -type d -name "2*" $NEWER`

for S in $SUBMISSIONS; do

    SUBMISSION=`basename "$S"`

    echo "Found $SUBMISSION"

    ARCHIVE="/tmp/${SUBMISSION}.zip"
    
    if [ -f $ARCHIVE ]; then
        rm $ARCHIVE
    fi
    
    cd $S
    zip $ARCHIVE * 1>/dev/null
    cd - 1>/dev/null
    
    PROJECT=`dirname $S`
    PROJECT=`basename $PROJECT`

    SIZE=`ls -la $ARCHIVE | awk '{ print $5 }'`

    TYPE=`cat $S/type 2>/dev/null`

    SUBJECT=$EMAIL_SUBJECT
    SUBJECT=`echo "$SUBJECT" | sed s/PROJECT/$PROJECT/`	
    SUBJECT=`echo "$SUBJECT" | sed s/SIZE/$SIZE/`	
    SUBJECT=`echo "$SUBJECT" | sed s/TYPE/$TYPE/`	

    REPLYTO=`cat $S/email`
        
    CONTENT="Feedback at ${SHOW_URL}?project=${PROJECT}&submission=${SUBMISSION}"

    (
        email "$EMAIL_FROM" "$EMAIL_TO" "$REPLYTO" "$SUBJECT" "$CONTENT" "$ARCHIVE"
    ) | sendmail -t

    rm $ARCHIVE

done

touch $TIMESTAMP
