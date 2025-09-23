{
  "displayName": "Rekor v2 Requests",
  "labels": {},
  "gridLayout": {
    "columns": 2,
    "widgets": [
%{ for shard in active_shards ~}
      {
        "title": "${shard} writes",
        "xyChart": {
          "chartOptions": {
            "displayHorizontal": false,
            "mode": "COLOR",
            "showLegend": false
          },
          "dataSets": [
          {
            "minAlignmentPeriod": "60s",
            "plotType": "STACKED_BAR",
            "targetAxis": "Y1",
            "timeSeriesQuery": {
              "outputFullDuration": false,
              "timeSeriesFilter": {
                "aggregation": {
                  "alignmentPeriod": "60s",
                  "crossSeriesReducer": "REDUCE_SUM",
                  "groupByFields": [
                    "metric.label.\"response_code\""
                  ],
                  "perSeriesAligner": "ALIGN_RATE"
                },
                "filter": "metric.type=\"loadbalancing.googleapis.com/https/backend_request_count\" resource.type=\"https_lb_rule\" resource.label.\"forwarding_rule_name\"=monitoring.regex.full_match(\"${shard}-rekor-https-forwarding-rule\") resource.label.\"matched_url_path_rule\"=\"/api/v2/log/entries\""
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
            "displayHorizontal": false,
            "mode": "COLOR",
            "showLegend": false
          },
          "dataSets": [
          {
            "minAlignmentPeriod": "60s",
            "plotType": "STACKED_BAR",
            "targetAxis": "Y1",
            "timeSeriesQuery": {
              "outputFullDuration": false,
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
                "filter": "metric.type=\"loadbalancing.googleapis.com/https/backend_request_count\" resource.type=\"https_lb_rule\" resource.label.\"forwarding_rule_name\"=monitoring.regex.full_match(\"${shard}-rekor-https-forwarding-rule\") resource.label.\"matched_url_path_rule\"=\"/api/v2/{path=**}\""
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
          "content": "End"
        }
      }
    ]
  }
}
