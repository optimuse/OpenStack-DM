#BASE_DIR=$(dirname $0)
BASE_DIR=$(dirname $BASH_SOURCE[0])
BASE_DIR=$(cd $BASE_DIR; pwd)


ENV_BASE="$BASE_DIR/env"
RC_BASE="$BASE_DIR/rc"
REPO_BASE="$BASE_DIR/repo"
CONF_BASE="$BASE_DIR/conf"
MAP_BASE="$BASE_DIR/map"
HELPER_BASE="$BASE_DIR/helper"
RELAY_BASE="$BASE_DIR/relay"
TOOL_BASE="$BASE_DIR/tool"
INST_BASE="$BASE_DIR/inst"
PLUG_BASE="$BASE_DIR/plugins"


[[ -f $ENV_BASE/my.ip ]] && source $ENV_BASE/my.ip
[[ -f $ENV_BASE/env.dynamic ]] && source $ENV_BASE/env.dynamic
[[ -f $ENV_BASE/env.token ]] && source $ENV_BASE/env.token
[[ -f $ENV_BASE/ceph-openstack/ceph-openstack.env ]] && source $ENV_BASE/ceph-openstack/ceph-openstack.env

source $ENV_BASE/env.base
source $ENV_BASE/env.ip
source $ENV_BASE/env.pass
