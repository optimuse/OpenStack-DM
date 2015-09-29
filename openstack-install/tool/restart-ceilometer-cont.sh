#!/bin/bash

systemctl restart openstack-ceilometer-api  \
    openstack-ceilometer-notification \
    openstack-ceilometer-central \
    openstack-ceilometer-collector \
    openstack-ceilometer-alarm-evaluator \
    openstack-ceilometer-alarm-notifier

