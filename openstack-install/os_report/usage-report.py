#!/bin/python

import sys
import argparse
import time
from datetime import datetime, timedelta, date
import MySQLdb
from influxdb import InfluxDBClient

def make_parser():
    parser = argparse.ArgumentParser(description='OpenStack Usage',
                                     epilog='Author: xiaopan.h@gmail.com')
    parser.add_argument('-s', help='start date time', dest='start')
    parser.add_argument('-e', help="end date time.", dest='end')
    parser.add_argument('-t', help="report type.", dest='report_type')
    return parser


## str <-> dt
def time_str_to_dt(t_str, t_format):
    t_tuple = time.strptime(t_str, t_format)
    t_ts = time.mktime(t_tuple)
    t_dt = datetime.fromtimestamp(t_ts)
    return t_dt

def time_dt_to_str(t_dt, t_format):
    return t_dt.strftime(t_format)


## local dt <-> utc dt
def time_udt_to_ldt(udt):
    now_ts = time.time()
    tz_offset = datetime.fromtimestamp(now_ts) - datetime.utcfromtimestamp(now_ts)
    ldt = udt + tz_offset
    return ldt

def time_ldt_to_udt(ldt):
    now_ts = time.time()
    tz_offset = datetime.fromtimestamp(now_ts) - datetime.utcfromtimestamp(now_ts)
    udt = ldt - tz_offset
    return udt


## local str -> utc str
def time_lstr_to_ustr(lstr, in_format, out_format=None):
    out_format = out_format if out_format is not None else in_format
    ldt = time_str_to_dt(lstr, in_format)
    udt = time_ldt_to_udt(ldt)
    ustr = time_dt_to_str(udt, out_format)
    return ustr


## datetime stored in database is in UTC format.
## so we should use utc format.

## DAY start time and end time determined by any one day.
def day_to_utc_time(day_dt):
    day = day_dt.strftime(T_DAY_FORMAT)
    day_local_time_start = day + " 00:00:00"
    day_local_time_end = day + " 23:59:59"
    day_utc_time_start = time_lstr_to_ustr(day_local_time_start, T_FULL_FORMAT)
    day_utc_time_end = time_lstr_to_ustr(day_local_time_end, T_FULL_FORMAT)
    return (day_utc_time_start, day_utc_time_end)

## MONTH start time and end time determined by any one day.
def month_to_utc_time(day_dt):
    first_day_of_month = date(day_dt.year, day_dt.month, 1)
    next_month = day_dt.month + 1
    if next_month > 12:
        first_day_of_nextmonth = date(day_dt.year + 1, 1, 1)
    else: 
        first_day_of_nextmonth = date(day_dt.year, next_month, 1)
    last_day_of_month = first_day_of_nextmonth - timedelta(1) 
    month_local_time_start = first_day_of_month.strftime(T_DAY_FORMAT) + " 00:00:00"
    month_local_time_end = last_day_of_month.strftime(T_DAY_FORMAT) + " 23:59:59"
    month_utc_time_start = time_lstr_to_ustr(month_local_time_start, T_FULL_FORMAT)
    month_utc_time_end = time_lstr_to_ustr(month_local_time_end, T_FULL_FORMAT)
    return (month_utc_time_start, month_utc_time_end)

# Week start time and end time determined by and one day.
def week_to_utc_time(day_dt):
    days_to_week = day_dt.weekday()
    first_day_of_week = day_dt - timedelta(days_to_week)
    last_day_of_week = first_day_of_week + timedelta(6)
    week_local_time_start = first_day_of_week.strftime(T_DAY_FORMAT) + " 00:00:00"
    week_local_time_end = last_day_of_week.strftime(T_DAY_FORMAT) + " 23:59:59"
    week_utc_time_start = time_lstr_to_ustr(week_local_time_start, T_FULL_FORMAT)
    week_utc_time_end = time_lstr_to_ustr(week_local_time_end, T_FULL_FORMAT)
    return (week_utc_time_start, week_utc_time_end)
    

SQL_TYPE_DICT = { 
                 "instance": "count(*)",
                 "vcpus": "COALESCE(sum(vcpus), 0)",
                 "memory": "COALESCE(sum(memory_mb), 0)",
                 "root": "COALESCE(sum(root_gb), 0)",
                 "volume": "count(*)",
                 "vol_size": " COALESCE(sum(size), 0)"
                }

def SQL_TIME_DICT_HELPER(time_start, time_end):
    sql_time_between = "BETWEEN '" + time_start + "' AND '" + time_end + "'"
    sql_time_created = "created_at BETWEEN '" + time_start + "' AND '" + time_end + "'"
    sql_time_deleted = "deleted_at BETWEEN '" + time_start + "' AND '" + time_end + "'"
    sql_time_exist = "created_at < '" + time_end + "' and ( deleted_at is NULL or deleted_at > '" + time_end + "' )"
   
    return {
            "created": sql_time_created,
            "deleted": sql_time_deleted,
            "exist": sql_time_exist
           }

                    
def build_sql_platform_usage_trend(res_type, res_action, res_table, time_start, time_end):
    SQL_TIME_DICT = SQL_TIME_DICT_HELPER(time_start, time_end)
    sql_temp = "select " + SQL_TYPE_DICT[res_type] + " from " + res_table + " where " + SQL_TIME_DICT[res_action]
    return sql_temp

def build_sql_tenant_usage_trend(res_type, res_action, res_table, time_start, time_end):
    SQL_TIME_DICT = SQL_TIME_DICT_HELPER(time_start, time_end)
    sql_temp = "select P.name, T.project_id, " + SQL_TYPE_DICT[res_type] + " \
                from " + res_table + " as T \
                inner join keystone.project as P \
                on T.project_id = P.id \
                where " + SQL_TIME_DICT[res_action] + " \
                group by T.project_id \
                order by name"
    return sql_temp

## !! Deprecated.
def build_sql_tenant_usage(res_table):
    # Tenant Usage
    sql_temp = "select P.name, Q.project_id, Q.resource, COALESCE(sum(Q.in_use), 0) as res_sum " + "\
                from " + res_table + " as Q \
                inner join keystone.project as P \
                on Q.project_id = P.id \
                group by Q.project_id, Q.resource"
    return sql_temp


def influx_point(measurement, tags, time, value):
    point = {
               "measurement": measurement,
               "tags": tags,
               "time": time,
               "fields": { "value": value }
            }
    return point


def os_platform_usage_trend(db, influx, report_type, res_type, res_action, res_table, time_start, time_end):
    measurement = "os_platform_usage_trend"
    sql_statement = build_sql_platform_usage_trend(res_type, res_action, res_table, time_start, time_end)
    cursor = db.cursor()
    cursor.execute(sql_statement);
    # single row result.
    value = float(cursor.fetchone()[0])
    
    tags = {
             "type": res_type,
             "action": res_action,
             "report_type": report_type
           }
    points = [influx_point(measurement, tags, time_end, value)]
    return points


def os_tenant_usage_trend(db, influx, report_type, res_type, res_action, res_table, time_start, time_end):
    measurement = "os_tenant_usage_trend"
    sql_statement = build_sql_tenant_usage_trend(res_type, res_action, res_table, time_start, time_end)
    cursor = db.cursor()
    cursor.execute(sql_statement)

    # multiple row result.
    points = []
    for row in cursor:
        tags = {
                  "tenantname": row[0],
                  "tenantid": row[1],
                  "type": res_type,
                  "action": res_action,
                  "report_type": report_type
               }
        value = float(row[2])
        points.append(influx_point(measurement, tags, time_end, value))
    return points


def os_resource_usage_trend(db, influx, report_type, res_type, res_action, res_table, time_start, time_end):
    points = []
    points += os_platform_usage_trend(db, influx, report_type, res_type, res_action, res_table, time_start, time_end)
    points += os_tenant_usage_trend(db, influx, report_type, res_type, res_action, res_table, time_start, time_end)
    return points


### cancel.

### !! Deprecated. tenant usage can be get through 'os_tenant_usage_trend'
def os_tenant_usage(db, influx, res_table, time_end):
    measurement = "os_tenant_usage_v2"
    # sql_temp = build_sql_tenant_usage("nova.quota_usages")
    sql_statement = build_sql_tenant_usage(res_table)
    cursor = db.cursor()
    cursor.execute(sql_statement)

    # multiple row result.
    # row[0] Project_name, row[1] Project_id, row[2] resource_name
    points = []
    for row in cursor:
        tags = {
                  "tenantname": row[0],
                  "tenantid": row[1],
                  "restype": row[2]
               }
        value = float(row[3])
        points.append(influx_point(measurement, tags, time_end, value))
    return points


def report_task(db, dest, report_type, time_start, time_end):

    points = []
    # Instance
    points += os_resource_usage_trend(db, dest, report_type, "instance", "created", "nova.instances", time_start, time_end)
    points += os_resource_usage_trend(db, dest, report_type, "instance", "deleted", "nova.instances", time_start, time_end)
    points += os_resource_usage_trend(db, dest, report_type, "instance", "exist", "nova.instances", time_start, time_end)
  
    # vCPUs
    points += os_resource_usage_trend(db, dest, report_type, "vcpus", "created", "nova.instances", time_start, time_end)
    points += os_resource_usage_trend(db, dest, report_type, "vcpus", "deleted", "nova.instances", time_start, time_end)
    points += os_resource_usage_trend(db, dest, report_type, "vcpus", "exist", "nova.instances", time_start, time_end)

    # Memory
    points += os_resource_usage_trend(db, dest, report_type, "memory", "created", "nova.instances", time_start, time_end)
    points += os_resource_usage_trend(db, dest, report_type, "memory", "deleted", "nova.instances", time_start, time_end)
    points += os_resource_usage_trend(db, dest, report_type, "memory", "exist", "nova.instances", time_start, time_end)

    # Root
    points += os_resource_usage_trend(db, dest, report_type, "root", "created", "nova.instances", time_start, time_end)
    points += os_resource_usage_trend(db, dest, report_type, "root", "deleted", "nova.instances", time_start, time_end)
    points += os_resource_usage_trend(db, dest, report_type, "root", "exist", "nova.instances", time_start, time_end)

    # volume
    points += os_resource_usage_trend(db, dest, report_type, "volume", "created", "cinder.volumes", time_start, time_end)
    points += os_resource_usage_trend(db, dest, report_type, "volume", "deleted", "cinder.volumes", time_start, time_end)
    points += os_resource_usage_trend(db, dest, report_type, "volume", "exist", "cinder.volumes", time_start, time_end)
    
    # vol_size (volume size)
    points += os_resource_usage_trend(db, dest, report_type, "vol_size", "created", "cinder.volumes", time_start, time_end)
    points += os_resource_usage_trend(db, dest, report_type, "vol_size", "deleted", "cinder.volumes", time_start, time_end)
    points += os_resource_usage_trend(db, dest, report_type, "vol_size", "exist", "cinder.volumes", time_start, time_end)

    ## Deprecated.
    points += os_tenant_usage(db, dest, "nova.quota_usages", time_end)
    
    dest.write_points(points)


def do_report(day_dt, report_type):
    influx = InfluxDBClient('10.5.255.5', 8086, 'influxadmin', 'influxadmin4test', 'os_report')
    db = MySQLdb.connect("localhost", "root", "mysql4openstack")

    if report_type == 'day':
        time_start, time_end = day_to_utc_time(day_dt)
    elif report_type == 'week':
        time_start, time_end = week_to_utc_time(day_dt)
    elif report_type == 'month':
        time_start, time_end = month_to_utc_time(day_dt)
    else:
        pass
 
    report_task(db, influx, report_type, time_start, time_end)
    db.close()


## Main Process.

parser = make_parser()
args = parser.parse_args()

T_DAY_FORMAT="%Y-%m-%d"
T_FULL_FORMAT="%Y-%m-%d %H:%M:%S"

# Nova query.

d_yestory = datetime.now() - timedelta(days=1)
d_yestory_str = d_yestory.strftime("%Y-%m-%d")

d1_str = args.start if args.start else d_yestory_str
d2_str = args.end if args.end else d_yestory_str
report_type = args.report_type if args.report_type else 'all'

d1_dt = time_str_to_dt(d1_str, T_DAY_FORMAT)
d2_dt = time_str_to_dt(d2_str, T_DAY_FORMAT)

for i in range((d2_dt - d1_dt).days + 1):
    day_choose = d1_dt + timedelta(days=i)
    print day_choose
    if report_type == "all":
        do_report(day_choose, "day")
        do_report(day_choose, "week")
        do_report(day_choose, "month")
    else:
        do_report(day_choose, report_type)
