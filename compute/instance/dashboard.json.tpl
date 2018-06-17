{
   "widgets": [
       {
          "type":"metric",
          "x":0,
          "y":0,
          "width":12,
          "height":6,
          "properties":{
             "metrics":[
                [
                   "AWS/EC2",
                   "CPUUtilization",
                   "InstanceId",
                   "${instance_id}"
                ]
             ],
             "period":300,
             "stat":"Average",
             "region":"${region}",
             "title":"EC2 Instance CPU"
          }
       }
   ]
 }