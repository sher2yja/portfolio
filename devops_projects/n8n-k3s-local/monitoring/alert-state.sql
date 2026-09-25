CREATE SCHEMA IF NOT EXISTS do14_ops;

CREATE TABLE IF NOT EXISTS do14_ops.alert_state (
  alertname text PRIMARY KEY,
  firing boolean NOT NULL
);
