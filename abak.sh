#!/bin/bash

day=`date +'%w'`

# list tables to exclude structure and resources
mysqldump -urcats -pmeoow rcats ab_access_permissions ab_adshare ab_adshare_orgs ab_biz_org ab_cat_types ab_features ab_group_users ab_groups ab_images ab_item_types ab_location ab_school ab_user_friends ab_users_cats content rcatdb_categories rcatdb_items rcatdb_ritems rcatdb_rcats users users_profile > /w/abra/databak/rcats.dump.$day


