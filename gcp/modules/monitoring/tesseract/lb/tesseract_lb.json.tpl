{
  "displayName": "CT Log (TesseraCT) Requests",
  "gridLayout": {
    "columns": "2",
    "widgets": [
%{ for shard in active_shards ~}
      {
        "title": "${shard} writes",
        "xyChart": {
          "chartOptions": {
            "mode": "COLOR"
          },
          "dataSets": [
          {
            "minAlignmentPeriod": "60s",
            "plotType": "STACKED_BAR",
            "targetAxis": "Y1",
            "timeSeriesQuery": {
              "timeSeriesFilter": {
                "aggregation": {
                  "alignmentPeriod": "60s",
                  "crossSeriesReducer": "REDUCE_SUM",
                  "groupByFields": [
                    "metric.label.\"response_code\""
                  ],
                  "perSeriesAligner": "ALIGN_RATE"
                },
                "filter": "metric.type=\"loadbalancing.googleapis.com/https/backend_request_count\" resource.type=\"https_lb_rule\" resource.label.\"forwarding_rule_name\"=monitoring.regex.full_match(\"${shard}-ctlog-https-forwarding-rule\") resource.label.\"matched_url_path_rule\"=\"/ct/v1/add-pre-chain\""
              }
            }
          }
          ],
          "yAxis": {
            "scale": "LINEAR"
          }
        }
      },
%{ endfor ~}
%{ for shard in all_shards ~}
      {
        "title": "${shard} reads",
        "xyChart": {
          "chartOptions": {
            "mode": "COLOR"
          },
          "dataSets": [
          {
            "minAlignmentPeriod": "60s",
            "plotType": "STACKED_BAR",
            "targetAxis": "Y1",
            "timeSeriesQuery": {
              "timeSeriesFilter": {
                "aggregation": {
                  "alignmentPeriod": "60s",
                  "crossSeriesReducer": "REDUCE_SUM",
                  "groupByFields": [
                    "metric.label.\"response_code\"",
                  "metric.label.\"cache_result\""
                  ],
                  "perSeriesAligner": "ALIGN_RATE"
                },
                "filter": "metric.type=\"loadbalancing.googleapis.com/https/backend_request_count\" resource.type=\"https_lb_rule\" resource.label.\"forwarding_rule_name\"=monitoring.regex.full_match(\"${shard}-ctlog-https-forwarding-rule\") resource.label.\"matched_url_path_rule\"=\"/*\""
              }
            }
          }
          ],
          "yAxis": {
            "scale": "LINEAR"
          }
        }
      },
%{ endfor ~}
      {
        "title": "End",
        "text": {
          "content": "End",
          "format": "MARKDOWN"
        }
      }
    ]
  }
}
