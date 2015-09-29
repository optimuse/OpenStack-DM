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
# def day_to_utc_time(t_str, t_format):
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
    

    
def get_sql_value(db, sql_statement):
    cursor = db.cursor()
    cursor.execute(sql_statement);
    res = float(cursor.fetchone()[0])
    return res


## Write os_resource_usage measurement to Influxdb.
def os_resource_usage(influx, tag_type, tag_action, tag_report_type, time, value):
    json_body = [
        {
            "measurement": "os_resource_usage",
            "tags": {
                "type": tag_type, "action": tag_action, "report_type": tag_report_type
            },
            "time": time,
            "fields": {
                "value": value
            }
        }
    ]
    influx.write_points(json_body)


def os_tenant_usage(influx, tag_tenantname, tag_tenantid, tag_restype, time, value):
    json_body = [
        {
            "measurement": "os_tenant_usage",
            "tags": {
                "tenantname": tag_tenantname, "tenantid": tag_tenantid, "restype": tag_restype
            },
            "time": time,
            "fields": {
                "value": value
            }
        }
    ]
    influx.write_points(json_body)


def report_task(db, dest, report_type, time_start, time_end):
    sql_time_between = "BETWEEN '" + time_start + "' AND '" + time_end + "'"
    
    sql_instance_created = "select count(*) from nova.instances where created_at " + sql_time_between
    sql_instance_deleted = "select count(*) from nova.instances where deleted_at " + sql_time_between
    sql_instance_exist = ("select count(*) from nova.instances where created_at < '" + time_end 
                              + "' and ( deleted_at is NULL or deleted_at > '" + time_end + "')" ) 
    
    os_resource_usage(dest, "instance", "created", report_type, time_end, get_sql_value(db, sql_instance_created))
    os_resource_usage(dest, "instance", "deleted", report_type, time_end, get_sql_value(db, sql_instance_deleted))
    os_resource_usage(dest, "instance", "exist", report_type, time_end, get_sql_value(db, sql_instance_exist))
    
    # vCPU, Memory, Root_GB
    sql_vcpus_created = "select COALESCE(sum(vcpus), 0) from nova.instances where created_at " + sql_time_between
    sql_vcpus_deleted = "select COALESCE(sum(vcpus),0 ) from nova.instances where deleted_at " + sql_time_between
    sql_vcpus_exist = ("select COALESCE(sum(vcpus),0 ) from nova.instances where created_at < '" + time_end 
                              + "' and ( deleted_at is NULL or deleted_at > '" + time_end + "')" ) 

    os_resource_usage(dest, "vcpus", "created", report_type, time_end, get_sql_value(db, sql_vcpus_created))
    os_resource_usage(dest, "vcpus", "deleted", report_type, time_end, get_sql_value(db, sql_vcpus_deleted))
    os_resource_usage(dest, "vcpus", "exist", report_type, time_end, get_sql_value(db, sql_vcpus_exist))

    sql_memory_created = "select COALESCE(sum(memory_mb), 0) from nova.instances where created_at " + sql_time_between
    sql_memory_deleted = "select COALESCE(sum(memory_mb), 0) from nova.instances where deleted_at " + sql_time_between
    sql_memory_exist = ("select COALESCE(sum(memory_mb), 0) from nova.instances where created_at < '" + time_end 
                              + "' and ( deleted_at is NULL or deleted_at > '" + time_end + "')" ) 

    os_resource_usage(dest, "memory", "created", report_type, time_end, get_sql_value(db, sql_memory_created))
    os_resource_usage(dest, "memory", "deleted", report_type, time_end, get_sql_value(db, sql_memory_deleted))
    os_resource_usage(dest, "memory", "exist", report_type, time_end, get_sql_value(db, sql_memory_exist))

    sql_root_created = "select COALESCE(sum(root_gb), 0) from nova.instances where created_at " + sql_time_between
    sql_root_deleted = "select COALESCE(sum(root_gb), 0) from nova.instances where deleted_at " + sql_time_between
    sql_root_exist = ("select COALESCE(sum(root_gb), 0) from nova.instances where created_at < '" + time_end 
                              + "' and ( deleted_at is NULL or deleted_at > '" + time_end + "')" ) 

    os_resource_usage(dest, "root", "created", report_type, time_end, get_sql_value(db, sql_root_created))
    os_resource_usage(dest, "root", "deleted", report_type, time_end, get_sql_value(db, sql_root_deleted))
    os_resource_usage(dest, "root", "exist", report_type, time_end, get_sql_value(db, sql_root_exist))


    # Cinder volumes.
    sql_volume_created = "select count(*) from cinder.volumes where created_at " + sql_time_between
    sql_volume_deleted = "select count(*) from cinder.volumes where deleted_at " + sql_time_between
    sql_volume_exist = ("select count(*) from cinder.volumes where created_at < '" + time_end 
                            + "' and ( deleted_at is NULL or deleted_at > '" + time_end + "')" ) 
    
    os_resource_usage(dest, "volume", "created", report_type, time_end, get_sql_value(db, sql_volume_created))
    os_resource_usage(dest, "volume", "deleted", report_type, time_end, get_sql_value(db, sql_volume_deleted))
    os_resource_usage(dest, "volume", "exist", report_type, time_end, get_sql_value(db, sql_volume_exist))

    # volume size.
    sql_volsize_created = "select COALESCE(sum(size), 0) from cinder.volumes where created_at " + sql_time_between
    sql_volsize_deleted = "select COALESCE(sum(size), 0) from cinder.volumes where deleted_at " + sql_time_between
    sql_volsize_exist = ("select COALESCE(sum(size), 0) from cinder.volumes where created_at < '" + time_end 
                              + "' and ( deleted_at is NULL or deleted_at > '" + time_end + "')" ) 
    
    os_resource_usage(dest, "volsize", "created", report_type, time_end, get_sql_value(db, sql_volsize_created))
    os_resource_usage(dest, "volsize", "deleted", report_type, time_end, get_sql_value(db, sql_volsize_deleted))
    os_resource_usage(dest, "volsize", "exist", report_type, time_end, get_sql_value(db, sql_volsize_exist))
   

    # Tenant Usage
    sql_tenant_usage = "select P.name, Q.project_id, Q.resource, COALESCE(sum(Q.in_use), 0) as res_sum \
                        from nova.quota_usages as Q \
                        inner join keystone.project as P \
                        on Q.project_id = P.id \
                        group by Q.project_id, Q.resource"

    cursor = db.cursor()
    cursor.execute(sql_tenant_usage)
    for row in cursor:
        os_tenant_usage(dest, row[0], row[1], row[2], time_end, row[3])


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
