//go:build !local
// +build !local

package main

import "go.uber.org/zap"

var logLevel = zap.DebugLevel

// var logLevel = zap.InfoLevel
var serviceName = ""
var local = false
var etcdEndpoints = "http://etcd-0.etcd-headless.core.svc.cluster.local:2379,http://etcd-1.etcd-headless.core.svc.cluster.local:2379,http://etcd-2.etcd-headless.core.svc.cluster.local:2379"
var port = ":8080"
var grpcAddr = "localhost:50051"
var firstPortMicroservice = 50052
var backoffLimit = int32(6)
var ttl = int32(30)
var activeDeadlineSeconds = int64(600)
var kubeconfig = ""
var rabbitMqUser = "normal_user"
var etcdJobRootKey = "/agents/jobs"
var tracingHost = "collector.linkerd-jaeger:55678"
// TTL (time-to-live) used for job queue in etcd (in seconds)
// TODO: set back to default after executed experiments, now 2 hours to execute energy experiments
var queueDeleteAfter = int64(7200)
// Old (default) setting of DYNAMOS: 10 minutes
// var queueDeleteAfter = int64(600)