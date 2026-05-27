{{/*
PrometheusRule alert groups for DataFlow Operator.
Included from templates/prometheusrule.yaml when monitoring.prometheusRule.enabled is true.
*/}}
{{- define "dataflow-operator.prometheusRuleGroups" -}}
groups:
  - name: dataflow-operator
    rules:
      - alert: DataFlowInError
        expr: dataflow_status{phase="Error"} == 1
        for: 2m
        labels:
          severity: critical
        annotations:
          summary: {{ printf "DataFlow {{ $labels.namespace }}/{{ $labels.name }} is in Error state" | quote }}
          description: {{ printf "DataFlow {{ $labels.namespace }}/{{ $labels.name }} has been in Error state for more than 2 minutes." | quote }}

      - alert: DataFlowConnectorDisconnected
        expr: dataflow_connector_connection_status == 0
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: {{ printf "DataFlow connector {{ $labels.namespace }}/{{ $labels.name }} is disconnected" | quote }}
          description: {{ printf "Connector {{ $labels.connector_type }}/{{ $labels.connector_name }} for DataFlow {{ $labels.namespace }}/{{ $labels.name }} has been disconnected for more than 5 minutes." | quote }}

      - alert: DataFlowHighErrorRate
        expr: |
          (
            sum(rate(dataflow_connector_errors_total[5m])) by (namespace, name)
            + sum(rate(dataflow_transformer_errors_total[5m])) by (namespace, name)
          )
          /
          sum(rate(dataflow_messages_received_total[5m])) by (namespace, name)
          > 0.01
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: {{ printf "DataFlow {{ $labels.namespace }}/{{ $labels.name }} has high error rate" | quote }}
          description: {{ printf "Error rate (connector + transformer errors) / messages received is above 1%% for {{ $labels.namespace }}/{{ $labels.name }}. Current value: {{ $value }}." | quote }}

      - alert: DataFlowSlowProcessing
        expr: |
          histogram_quantile(0.95,
            sum(rate(dataflow_processing_duration_seconds_bucket[5m])) by (namespace, name, le)
          ) > 1
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: {{ printf "DataFlow {{ $labels.namespace }}/{{ $labels.name }} has slow message processing" | quote }}
          description: {{ printf "p95 message processing duration is above 1 second for {{ $labels.namespace }}/{{ $labels.name }}. Current value: {{ $value }}s." | quote }}

      - alert: DataFlowLowTaskSuccessRate
        expr: dataflow_task_success_rate < 0.95
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: {{ printf "DataFlow {{ $labels.namespace }}/{{ $labels.name }} has low task success rate" | quote }}
          description: {{ printf "Task success rate is below 95%% for {{ $labels.namespace }}/{{ $labels.name }}. Current value: {{ $value }}." | quote }}

      - alert: DataFlowHighQueueSize
        expr: dataflow_task_queue_size > 1000
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: {{ printf "DataFlow {{ $labels.namespace }}/{{ $labels.name }} has high queue size" | quote }}
          description: {{ printf "Queue {{ $labels.queue_type }} for {{ $labels.namespace }}/{{ $labels.name }} exceeds 1000 messages. Current value: {{ $value }}." | quote }}

      - alert: DataFlowHighE2ELatency
        expr: |
          histogram_quantile(0.99,
            sum(rate(dataflow_task_end_to_end_latency_seconds_bucket[5m])) by (namespace, name, le)
          ) > 5
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: {{ printf "DataFlow {{ $labels.namespace }}/{{ $labels.name }} has high end-to-end latency" | quote }}
          description: {{ printf "p99 end-to-end latency is above 5 seconds for {{ $labels.namespace }}/{{ $labels.name }}. Current value: {{ $value }}s." | quote }}

      - alert: DataFlowPipelineStalled
        expr: |
          dataflow_status{phase="Running"} == 1
          and (
            sum(rate(dataflow_messages_received_total[15m])) by (namespace, name) == 0
            or sum(rate(dataflow_messages_sent_total[15m])) by (namespace, name) == 0
          )
          and (
            sum(rate(dataflow_connector_errors_total[15m])) by (namespace, name) > 0
            or dataflow_task_throughput_messages_per_second == 0
          )
        for: 10m
        labels:
          severity: warning
        annotations:
          summary: {{ printf "DataFlow {{ $labels.namespace }}/{{ $labels.name }} pipeline stalled" | quote }}
          description: {{ printf "DataFlow {{ $labels.namespace }}/{{ $labels.name }} is Running but has no message throughput for 10+ minutes (possible Kafka consumer hang or sink stall)." | quote }}

      - alert: DataFlowKafkaFetchTimeouts
        expr: |
          sum(rate(dataflow_connector_errors_total{operation="read",error_type="request_timed_out"}[5m])) by (namespace, name) > 0.1
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: {{ printf "DataFlow {{ $labels.namespace }}/{{ $labels.name }} has frequent Kafka fetch timeouts" | quote }}
          description: {{ printf "Kafka source for {{ $labels.namespace }}/{{ $labels.name }} is reporting request_timed_out errors (>0.1/s). Consider tuning consumerMaxWait and netReadTimeout in the DataFlow CR." | quote }}
{{- end }}
