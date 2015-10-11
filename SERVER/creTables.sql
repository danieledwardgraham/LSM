use test;

drop table meas_vals;
create table meas_vals (TopId int(5),
    Key1 varchar(50),
    Key2 varchar(50),
    Key3 varchar(50),
    Key4 varchar(50),
    Key5 varchar(50),
    Key6 varchar(50),
    Key7 varchar(50),
    Key8 varchar(50),
    Key9 varchar(50),
    Key10 varchar(50),
    Key11 varchar(50),
    Key12 varchar(50),
    Key13 varchar(50),
    Key14 varchar(50),
    Key15 varchar(50),
    counter varchar(50),
    meas_time datetime,
    agg_hour boolean,
    agg_day boolean,
    agg_week boolean,
    agg_month boolean,
    val decimal(12,4));

drop index meas_vals_ind1 on meas_vals;
create index meas_vals_ind1 on meas_vals(meas_time);
drop index meas_vals_ind2 on meas_vals;
create index meas_vals_ind2 on meas_vals(agg_hour);
drop index meas_vals_ind3 on meas_vals;
create index meas_vals_ind3 on meas_vals(agg_day);
drop index meas_vals_ind4 on meas_vals;
create index meas_vals_ind4 on meas_vals(agg_week);
drop index meas_vals_ind5 on meas_vals;
create index meas_vals_ind5 on meas_vals(agg_month);
drop index meas_vals_ind6 on meas_vals;
create index meas_vals_ind6 on meas_vals(Key1);
drop index meas_vals_ind7 on meas_vals;
create index meas_vals_ind7 on meas_vals(Key2);
drop index meas_vals_ind8 on meas_vals;
create index meas_vals_ind8 on meas_vals(Key3);
drop index meas_vals_ind9 on meas_vals;
create index meas_vals_ind9 on meas_vals(Key4);
drop index meas_vals_ind10 on meas_vals;
create index meas_vals_ind10 on meas_vals(Key5);
drop index meas_vals_ind11 on meas_vals;
create index meas_vals_ind11 on meas_vals(Key6);
drop index meas_vals_ind12 on meas_vals;
create index meas_vals_ind12 on meas_vals(Key7);
drop index meas_vals_ind13 on meas_vals;
create index meas_vals_ind13 on meas_vals(Key8);
drop index meas_vals_ind14 on meas_vals;
create index meas_vals_ind14 on meas_vals(Key9);
drop index meas_vals_ind15 on meas_vals;
create index meas_vals_ind15 on meas_vals(Key10);
drop index meas_vals_ind16 on meas_vals;
create index meas_vals_ind16 on meas_vals(Key11);
drop index meas_vals_ind17 on meas_vals;
create index meas_vals_ind17 on meas_vals(Key12);
drop index meas_vals_ind18 on meas_vals;
create index meas_vals_ind18 on meas_vals(Key13);
drop index meas_vals_ind19 on meas_vals;
create index meas_vals_ind19 on meas_vals(Key14);
drop index meas_vals_ind20 on meas_vals;
create index meas_vals_ind20 on meas_vals(Key15);
drop index meas_vals_ind21 on meas_vals;
create index meas_vals_ind21 on meas_vals(TopId);
drop index meas_vals_ind22 on meas_vals;
create index meas_vals_ind22 on meas_vals(counter);
drop index meas_vals_ind23 on meas_vals;
create index meas_vals_ind23 on meas_vals(val);

drop table topo_def;
create table topo_def (TopId int(5),
    TKey1 varchar(50),
    TKey2 varchar(50),
    TKey3 varchar(50),
    TKey4 varchar(50),
    TKey5 varchar(50),
    TKey6 varchar(50),
    TKey7 varchar(50),
    TKey8 varchar(50),
    TKey9 varchar(50),
    TKey10 varchar(50),
    TKey11 varchar(50),
    TKey12 varchar(50),
    TKey13 varchar(50),
    TKey14 varchar(50),
    Tkey15 varchar(50));

drop index topo_def_ind1 on topo_def;
create index topo_def_ind1 on topo_def(TopId);
drop index topo_def_ind2 on topo_def;
create index topo_def_ind2 on topo_def(TKey1);
drop index topo_def_ind3 on topo_def;
create index topo_def_ind3 on topo_def(TKey2);
drop index topo_def_ind4 on topo_def;
create index topo_def_ind4 on topo_def(TKey3);
drop index topo_def_ind5 on topo_def;
create index topo_def_ind5 on topo_def(TKey4);
drop index topo_def_ind6 on topo_def;
create index topo_def_ind6 on topo_def(TKey5);
drop index topo_def_ind7 on topo_def;
create index topo_def_ind7 on topo_def(TKey6);
drop index topo_def_ind8 on topo_def;
create index topo_def_ind8 on topo_def(TKey7);
drop index topo_def_ind9 on topo_def;
create index topo_def_ind9 on topo_def(TKey8);
drop index topo_def_ind10 on topo_def;
create index topo_def_ind10 on topo_def(TKey9);
drop index topo_def_ind11 on topo_def;
create index topo_def_ind11 on topo_def(TKey10);
drop index topo_def_ind12 on topo_def;
create index topo_def_ind12 on topo_def(TKey11);
drop index topo_def_ind13 on topo_def;
create index topo_def_ind13 on topo_def(TKey12);
drop index topo_def_ind14 on topo_def;
create index topo_def_ind14 on topo_def(TKey13);
drop index topo_def_ind15 on topo_def;
create index topo_def_ind15 on topo_def(TKey14);
drop index topo_def_ind16 on topo_def;
create index topo_def_ind16 on topo_def(TKey15);

drop table topo_desc; 
create table topo_desc (TopId int(5),
    TKeyDesc1 varchar(50),
    TKeyDesc2 varchar(50),
    TKeyDesc3 varchar(50),
    TKeyDesc4 varchar(50),
    TKeyDesc5 varchar(50),
    TKeyDesc6 varchar(50),
    TKeyDesc7 varchar(50),
    TKeyDesc8 varchar(50),
    TKeyDesc9 varchar(50),
    TKeyDesc10 varchar(50),
    TKeyDesc11 varchar(50),
    TKeyDesc12 varchar(50),
    TKeyDesc13 varchar(50),
    TKeyDesc14 varchar(50),
    TKeyDesc15 varchar(50));

drop index topo_desc_ind1 on topo_desc;
create index topo_desc_ind1 on topo_desc(TopId);

drop table count_desc;
create table count_desc (TopId int(5),
    counter varchar(50),
    countDesc varchar(50));

drop index count_desc_ind1 on count_desc;
create index count_desc_ind1 on count_desc(TopId);
drop index count_desc_ind2 on count_desc;
create index count_desc_ind2 on count_desc(counter);

drop table meas_types;
create table meas_types (TopId int(5),
    counter varchar(50),
    percent bool,
    sumA bool,
    avgA bool,
    maxA bool,
    minA bool);

drop index meas_types_ind1 on meas_types;
create index meas_types_ind1 on meas_types(TopId);
drop index meas_types_ind2 on meas_types;
create index meas_types_ind2 on meas_types(counter);

drop table hourly_agg;
create table hourly_agg (TopId int(5),
    Key1 varchar(50),
    Key2 varchar(50),
    Key3 varchar(50),
    Key4 varchar(50),
    Key5 varchar(50),
    Key6 varchar(50),
    Key7 varchar(50),
    Key8 varchar(50),
    Key9 varchar(50),
    Key10 varchar(50),
    Key11 varchar(50),
    Key12 varchar(50),
    Key13 varchar(50),
    Key14 varchar(50),
    Key15 varchar(50),
    meas_time datetime,
    counter varchar(50),
    countTopId int(5),
    time_hour datetime,
    agg_type varchar(10),
    val decimal(12,4));

drop index hourly_agg_ind1 on hourly_agg;
create index hourly_agg_ind1 on hourly_agg(Key1);
drop index hourly_agg_ind2 on hourly_agg;
create index hourly_agg_ind2 on hourly_agg(Key2);
drop index hourly_agg_ind3 on hourly_agg;
create index hourly_agg_ind3 on hourly_agg(Key3);
drop index hourly_agg_ind4 on hourly_agg;
create index hourly_agg_ind4 on hourly_agg(Key4);
drop index hourly_agg_ind5 on hourly_agg;
create index hourly_agg_ind5 on hourly_agg(Key5);
drop index hourly_agg_ind6 on hourly_agg;
create index hourly_agg_ind6 on hourly_agg(Key6);
drop index hourly_agg_ind7 on hourly_agg;
create index hourly_agg_ind7 on hourly_agg(Key7);
drop index hourly_agg_ind8 on hourly_agg;
create index hourly_agg_ind8 on hourly_agg(Key8);
drop index hourly_agg_ind9 on hourly_agg;
create index hourly_agg_ind9 on hourly_agg(Key9);
drop index hourly_agg_ind10 on hourly_agg;
create index hourly_agg_ind10 on hourly_agg(Key10);
drop index hourly_agg_ind11 on hourly_agg;
create index hourly_agg_ind11 on hourly_agg(Key11);
drop index hourly_agg_ind12 on hourly_agg;
create index hourly_agg_ind12 on hourly_agg(Key12);
drop index hourly_agg_ind13 on hourly_agg;
create index hourly_agg_ind13 on hourly_agg(Key13);
drop index hourly_agg_ind14 on hourly_agg;
create index hourly_agg_ind14 on hourly_agg(Key14);
drop index hourly_agg_ind15 on hourly_agg;
create index hourly_agg_ind15 on hourly_agg(Key15);
drop index hourly_agg_ind16 on hourly_agg;
create index hourly_agg_ind16 on hourly_agg(TopId);
drop index hourly_agg_ind17 on hourly_agg;
create index hourly_agg_ind17 on hourly_agg(counter);
drop index hourly_agg_ind18 on hourly_agg;
create index hourly_agg_ind18 on hourly_agg(time_hour);
drop index hourly_agg_ind19 on hourly_agg;
create index hourly_agg_ind19 on hourly_agg(agg_type);
drop index hourly_agg_ind20 on hourly_agg;
create index hourly_agg_ind20 on hourly_agg(countTopId);

drop table daily_agg;
create table daily_agg (TopId int(5),
    Key1 varchar(50),
    Key2 varchar(50),
    Key3 varchar(50),
    Key4 varchar(50),
    Key5 varchar(50),
    Key6 varchar(50),
    Key7 varchar(50),
    Key8 varchar(50),
    Key9 varchar(50),
    Key10 varchar(50),
    Key11 varchar(50),
    Key12 varchar(50),
    Key13 varchar(50),
    Key14 varchar(50),
    Key15 varchar(50),
    meas_time datetime,
    counter varchar(50),
    countTopId int(5),
    time_day datetime,
    agg_type varchar(10),
    val decimal(12,4));

drop index daily_agg_ind1 on daily_agg;
create index daily_agg_ind1 on daily_agg(Key1);
drop index daily_agg_ind2 on daily_agg;
create index daily_agg_ind2 on daily_agg(Key2);
drop index daily_agg_ind3 on daily_agg;
create index daily_agg_ind3 on daily_agg(Key3);
drop index daily_agg_ind4 on daily_agg;
create index daily_agg_ind4 on daily_agg(Key4);
drop index daily_agg_ind5 on daily_agg;
create index daily_agg_ind5 on daily_agg(Key5);
drop index daily_agg_ind6 on daily_agg;
create index daily_agg_ind6 on daily_agg(Key6);
drop index daily_agg_ind7 on daily_agg;
create index daily_agg_ind7 on daily_agg(Key7);
drop index daily_agg_ind8 on daily_agg;
create index daily_agg_ind8 on daily_agg(Key8);
drop index daily_agg_ind9 on daily_agg;
create index daily_agg_ind9 on daily_agg(Key9);
drop index daily_agg_ind10 on daily_agg;
create index daily_agg_ind10 on daily_agg(Key10);
drop index daily_agg_ind11 on daily_agg;
create index daily_agg_ind11 on daily_agg(Key11);
drop index daily_agg_ind12 on daily_agg;
create index daily_agg_ind12 on daily_agg(Key12);
drop index daily_agg_ind13 on daily_agg;
create index daily_agg_ind13 on daily_agg(Key13);
drop index daily_agg_ind14 on daily_agg;
create index daily_agg_ind14 on daily_agg(Key14);
drop index daily_agg_ind15 on daily_agg;
create index daily_agg_ind15 on daily_agg(Key15);
drop index daily_agg_ind16 on daily_agg;
create index daily_agg_ind16 on daily_agg(TopId);
drop index daily_agg_ind17 on daily_agg;
create index daily_agg_ind17 on daily_agg(counter);
drop index daily_agg_ind18 on daily_agg;
create index daily_agg_ind18 on daily_agg(time_day);
drop index daily_agg_ind19 on daily_agg;
create index daily_agg_ind19 on daily_agg(agg_type);
drop index daily_agg_ind20 on daily_agg;
create index daily_agg_ind20 on daily_agg(countTopId);

drop table weekly_agg;
create table weekly_agg (TopId int(5),
    Key1 varchar(50),
    Key2 varchar(50),
    Key3 varchar(50),
    Key4 varchar(50),
    Key5 varchar(50),
    Key6 varchar(50),
    Key7 varchar(50),
    Key8 varchar(50),
    Key9 varchar(50),
    Key10 varchar(50),
    Key11 varchar(50),
    Key12 varchar(50),
    Key13 varchar(50),
    Key14 varchar(50),
    Key15 varchar(50),
    meas_time datetime,
    counter varchar(50),
    countTopId int(5),
    time_week datetime,
    agg_type varchar(10),
    val decimal(12,4));

drop index weekly_agg_ind1 on weekly_agg;
create index weekly_agg_ind1 on weekly_agg(Key1);
drop index weekly_agg_ind2 on weekly_agg;
create index weekly_agg_ind2 on weekly_agg(Key2);
drop index weekly_agg_ind3 on weekly_agg;
create index weekly_agg_ind3 on weekly_agg(Key3);
drop index weekly_agg_ind4 on weekly_agg;
create index weekly_agg_ind4 on weekly_agg(Key4);
drop index weekly_agg_ind5 on weekly_agg;
create index weekly_agg_ind5 on weekly_agg(Key5);
drop index weekly_agg_ind6 on weekly_agg;
create index weekly_agg_ind6 on weekly_agg(Key6);
drop index weekly_agg_ind7 on weekly_agg;
create index weekly_agg_ind7 on weekly_agg(Key7);
drop index weekly_agg_ind8 on weekly_agg;
create index weekly_agg_ind8 on weekly_agg(Key8);
drop index weekly_agg_ind9 on weekly_agg;
create index weekly_agg_ind9 on weekly_agg(Key9);
drop index weekly_agg_ind10 on weekly_agg;
create index weekly_agg_ind10 on weekly_agg(Key10);
drop index weekly_agg_ind11 on weekly_agg;
create index weekly_agg_ind11 on weekly_agg(Key11);
drop index weekly_agg_ind12 on weekly_agg;
create index weekly_agg_ind12 on weekly_agg(Key12);
drop index weekly_agg_ind13 on weekly_agg;
create index weekly_agg_ind13 on weekly_agg(Key13);
drop index weekly_agg_ind14 on weekly_agg;
create index weekly_agg_ind14 on weekly_agg(Key14);
drop index weekly_agg_ind15 on weekly_agg;
create index weekly_agg_ind15 on weekly_agg(Key15);
drop index weekly_agg_ind16 on weekly_agg;
create index weekly_agg_ind16 on weekly_agg(TopId);
drop index weekly_agg_ind17 on weekly_agg;
create index weekly_agg_ind17 on weekly_agg(counter);
drop index weekly_agg_ind18 on weekly_agg;
create index weekly_agg_ind18 on weekly_agg(time_week);
drop index weekly_agg_ind19 on weekly_agg;
create index weekly_agg_ind19 on weekly_agg(agg_type);
drop index weekly_agg_ind20 on weekly_agg;
create index weekly_agg_ind20 on weekly_agg(countTopId);

drop table monthly_agg;
create table monthly_agg (TopId int(5),
    Key1 varchar(50),
    Key2 varchar(50),
    Key3 varchar(50),
    Key4 varchar(50),
    Key5 varchar(50),
    Key6 varchar(50),
    Key7 varchar(50),
    Key8 varchar(50),
    Key9 varchar(50),
    Key10 varchar(50),
    Key11 varchar(50),
    Key12 varchar(50),
    Key13 varchar(50),
    Key14 varchar(50),
    Key15 varchar(50),
    meas_time datetime,
    counter varchar(50),
    countTopId int(5),
    time_month datetime,
    agg_type varchar(10),
    val decimal(12,4));

drop index monthly_agg_ind1 on monthly_agg;
create index monthly_agg_ind1 on monthly_agg(Key1);
drop index monthly_agg_ind2 on monthly_agg;
create index monthly_agg_ind2 on monthly_agg(Key2);
drop index monthly_agg_ind3 on monthly_agg;
create index monthly_agg_ind3 on monthly_agg(Key3);
drop index monthly_agg_ind4 on monthly_agg;
create index monthly_agg_ind4 on monthly_agg(Key4);
drop index monthly_agg_ind5 on monthly_agg;
create index monthly_agg_ind5 on monthly_agg(Key5);
drop index monthly_agg_ind6 on monthly_agg;
create index monthly_agg_ind6 on monthly_agg(Key6);
drop index monthly_agg_ind7 on monthly_agg;
create index monthly_agg_ind7 on monthly_agg(Key7);
drop index monthly_agg_ind8 on monthly_agg;
create index monthly_agg_ind8 on monthly_agg(Key8);
drop index monthly_agg_ind9 on monthly_agg;
create index monthly_agg_ind9 on monthly_agg(Key9);
drop index monthly_agg_ind10 on monthly_agg;
create index monthly_agg_ind10 on monthly_agg(Key10);
drop index monthly_agg_ind11 on monthly_agg;
create index monthly_agg_ind11 on monthly_agg(Key11);
drop index monthly_agg_ind12 on monthly_agg;
create index monthly_agg_ind12 on monthly_agg(Key12);
drop index monthly_agg_ind13 on monthly_agg;
create index monthly_agg_ind13 on monthly_agg(Key13);
drop index monthly_agg_ind14 on monthly_agg;
create index monthly_agg_ind14 on monthly_agg(Key14);
drop index monthly_agg_ind15 on monthly_agg;
create index monthly_agg_ind15 on monthly_agg(Key15);
drop index monthly_agg_ind16 on monthly_agg;
create index monthly_agg_ind16 on monthly_agg(TopId);
drop index monthly_agg_ind17 on monthly_agg;
create index monthly_agg_ind17 on monthly_agg(counter);
drop index monthly_agg_ind18 on monthly_agg;
create index monthly_agg_ind18 on monthly_agg(time_month);
drop index monthly_agg_ind19 on monthly_agg;
create index monthly_agg_ind19 on monthly_agg(agg_type);
drop index monthly_agg_ind20 on monthly_agg;
create index monthly_agg_ind20 on monthly_agg(countTopId);

