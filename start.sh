#!/bin/bash
 
PARSED_OPTIONS=$(getopt -n "$0" -o h -l "help,name:,conf:,path:,build:,deploy"  -- "$@")


#Bad arguments, something has gone wrong with the getopt command.
if [ $? -ne 0 ];
then
  exit 1
fi
 
# A little magic, necessary when using getopt.
eval set -- "$PARSED_OPTIONS"

usage() { echo "usage $0 --path=<apps path>" 1>&2; exit 1; } 

DEPLOY=0

while true;
do
  case "$1" in
 
    -h|--help)
      usage
     shift;;
    
    --name)
      APP_NAME=$2
      shift 2;;

    --path)
      APP_DIR=$2
      shift 2;;
    
    --conf)
      APP_CONF=$2
      shift 2;;

    --build)
      APP_BUILD=$2
      shift 2;;
    
    --deploy)
      DEPLOY=1
      shift;;

    --)
      shift
      break;;
  esac
done

if [ -z $APP_DIR ]; then
  usage
fi
if [ -z $APP_NAME ]; then
  usage
fi

APP_PATH="$APP_DIR/$APP_NAME"

if [ -f "$APP_PATH/RUNNING_PID" ]; then
  echo "-----> Stopping old app"
  kill -9 `cat $APP_PATH/RUNNING_PID`
fi

if [ $DEPLOY == 1 ] && [ -d $APP_BUILD ]; then
  echo "-----> Deploy app from $APP_BUILD"
  if [ -d $APP_PATH ]; then
    rm -rf $APP_PATH
  fi
  cp -R $APP_BUILD $APP_PATH
fi

Xms=128m
Xmx=128m
opts=()
if [ ! -z $APP_CONF ]; then
  echo "-----> load config $APP_CONF"
  source "$APP_PATH/conf/$APP_CONF"
fi

options=""
for var in ${opts[@]}; do
  options="$options -D$var"
done

echo "-----> Starting $APP_NAME"

if [ ! -d $APP_PATH ]; then
  echo "Start failed. app not found: $APP_PATH"
  exit 1
fi

cd $APP_PATH
./target/start -Xms$Xms -Xmx$Xmx $options &