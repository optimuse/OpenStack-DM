#!/bin/bash

NET=$1
nova-manage network modify --fixed_range $NET --disassociate-project
nova-manage network delete --fixed_range $NET
