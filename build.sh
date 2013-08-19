#!/bin/bash
START_SCRIPT="$HOME/buildkit/start.sh"

PARSED_OPTIONS=$(getopt -n "$0" -o h -l "help,name:,build:,git:,branch:,conf:,path:,Xms:,Xmx:"  -- "$@")


#Bad arguments, something has gone wrong with the getopt command.
if [ $? -ne 0 ];
then
  exit 1
fi
 
# A little magic, necessary when using getopt.
eval set -- "$PARSED_OPTIONS"

usage() { echo "usage $0 --name=<name> --git=<path/to/repo.git> --build=<build dir> --path=<app dir> --branch=<branch> --Xms=786m --Xmx=786m" 1>&2; exit 1; } 

GIT_BRANCH="origin/master"
Xms="1024m"
Xmx="1024m"
while true;
do
  case "$1" in
 
    -h|--help)
      usage
     shift;;
 
    --name)
      APP_NAME=$2
      shift 2;;

    --build)
      BUILD_DIR=$2
      shift 2;;
 
    --git)
      APP_GIT=$2
      shift 2;;

    --path)
      APP_DIR=$2
      shift 2;;

    --conf)
      APP_CONF=$2
      shift 2;;
 
    --branch)
      GIT_BRANCH=$2
      shift 2;;
 
    --)
      shift
      break;;
  esac
done

if [ -z $APP_NAME ]; then
    echo "Missing name"
    usage
fi
if [ -z $APP_GIT ]; then
    echo "Missing git url"
    usage
fi
if [ -z $BUILD_DIR ]; then
    echo "Missing build path"
    usage
fi

APP_BUILD="$BUILD_DIR/$APP_NAME"

mkdir -p $BUILD_DIR
if [ -d $APP_BUILD ]; then
   rm -rf $APP_BUILD
fi
cd $BUILD_DIR

echo "-----> Clone app $APP_NAME"
git clone $APP_GIT $APP_NAME

echo "-----> Build app $APP_NAME"
cd $APP_NAME
export SBT_OPTS="-Xms$Xms -Xmx$Xmx"
sbt clean compile stage

if [ $? != 0 ]; then
  exit 1
fi

CONF=""
if [ ! -z $APP_CONF ]; then
  CONF="--conf=$APP_CONF"
fi

APP_START="$APP_BUILD/start"
echo "-----> Generate start script $APP_START"
cat > $APP_START << EOF
#!/bin/sh
$START_SCRIPT --name=$APP_NAME --path=$APP_DIR --build=$APP_BUILD $CONF \$@
EOF

chmod +x $APP_START
