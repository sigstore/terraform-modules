{
  "displayName": "CT Log (TesseraCT) ",
  "gridLayout": {
    "columns": "2",
    "widgets": [
      {
        "title": "Tree Size",
        "scorecard": {
          "sparkChartView": {
            "sparkChartType": "SPARK_LINE"
          },
          "timeSeriesQuery": {
            "outputFullDuration": true,
            "timeSeriesFilter": {
              "aggregation": {
                "alignmentPeriod": "60s",
                "crossSeriesReducer": "REDUCE_SUM",
                "perSeriesAligner": "ALIGN_MEAN"
              },
              "filter": "metric.type=\"workload.googleapis.com/tessera.appender.integrated.size\" resource.type=\"k8s_cluster\""
            }
          }
        }
      },
      {
        "title": "Requests by SCT operation",
        "xyChart": {
          "chartOptions": {
            "mode": "COLOR"
          },
          "dataSets": [
            {
              "minAlignmentPeriod": "60s",
              "plotType": "LINE",
              "targetAxis": "Y1",
              "timeSeriesQuery": {
                "timeSeriesFilter": {
                  "aggregation": {
                    "alignmentPeriod": "60s",
                    "crossSeriesReducer": "REDUCE_SUM",
                    "groupByFields": [
                      "metric.label.\"tesseract_operation\""
                    ],
                    "perSeriesAligner": "ALIGN_RATE"
                  },
                  "filter": "metric.type=\"workload.googleapis.com/tesseract.http.request.count\" resource.type=\"k8s_cluster\""
                }
              }
            }
          ],
          "yAxis": {
            "scale": "LINEAR"
          }
        }
      },
      {
        "title": "TesseraCT HTTP Request Duration",
        "xyChart": {
          "chartOptions": {
            "mode": "COLOR"
          },
          "dataSets": [
            {
              "minAlignmentPeriod": "60s",
              "plotType": "HEATMAP",
              "targetAxis": "Y1",
              "timeSeriesQuery": {
                "timeSeriesFilter": {
                  "aggregation": {
                    "alignmentPeriod": "60s",
                    "crossSeriesReducer": "REDUCE_SUM",
                    "perSeriesAligner": "ALIGN_DELTA"
                  },
                  "filter": "metric.type=\"workload.googleapis.com/tesseract.http.request.duration\" resource.type=\"k8s_cluster\""
                }
              }
            }
          ],
          "yAxis": {
            "scale": "LINEAR"
          }
        }
      },
      {
        "title": "Tessera Appender Duration",
        "xyChart": {
          "chartOptions": {
            "mode": "COLOR"
          },
          "dataSets": [
            {
              "minAlignmentPeriod": "60s",
              "plotType": "HEATMAP",
              "targetAxis": "Y1",
              "timeSeriesQuery": {
                "timeSeriesFilter": {
                  "aggregation": {
                    "alignmentPeriod": "60s",
                    "crossSeriesReducer": "REDUCE_SUM",
                    "perSeriesAligner": "ALIGN_DELTA"
                  },
                  "filter": "metric.type=\"workload.googleapis.com/tessera.appender.add.duration\" resource.type=\"k8s_cluster\""
                }
              }
            }
          ],
          "yAxis": {
            "scale": "LINEAR"
          }
        }
      },
      {
        "title": "SLO Health: 99.5% Availability (HTTP Server) : /ct/v1/add-pre-chain - POST",
        "xyChart": {
          "dataSets": [
            {
              "plotType": "LINE",
              "timeSeriesQuery": {
                "timeSeriesFilter": {
                  "aggregation": {
                    "perSeriesAligner": "ALIGN_MEAN"
                  },
                  "filter": "select_slo_health(\"slo_id\")"
                },
                "unitOverride": "10^2.%"
              }
            }
          ],
          "thresholds": [
            {
              "value": 0.995
            }
          ]
        }
      }
    ]
  }
}
