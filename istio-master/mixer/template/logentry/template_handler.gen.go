// Copyright 2017 Istio Authors
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

// THIS FILE IS AUTOMATICALLY GENERATED.

package logentry

import (
	"context"
	"time"

	"istio.io/istio/mixer/pkg/adapter"
)

// The `logentry` template represents an individual entry within a log.
//
// Example config:
//
// ```yaml
// apiVersion: "config.istio.io/v1alpha2"
// kind: logentry
// metadata:
//   name: accesslog
//   namespace: istio-system
// spec:
//   severity: '"Default"'
//   timestamp: request.time
//   variables:
//     sourceIp: source.ip | ip("0.0.0.0")
//     destinationIp: destination.ip | ip("0.0.0.0")
//     sourceUser: source.principal | ""
//     method: request.method | ""
//     url: request.path | ""
//     protocol: request.scheme | "http"
//     responseCode: response.code | 0
//     responseSize: response.size | 0
//     requestSize: request.size | 0
//     latency: response.duration | "0ms"
//   monitored_resource_type: '"UNSPECIFIED"'
// ```

// Fully qualified name of the template
const TemplateName = "logentry"

// Instance is constructed by Mixer for the 'logentry' template.
//
// The `logentry` template represents an individual entry within a log.
//
// When writing the configuration, the value for the fields associated with this template can either be a
// literal or an [expression](https://istio.io/docs/reference//config/policy-and-telemetry/expression-language/). Please note that if the datatype of a field is not istio.policy.v1beta1.Value,
// then the expression's [inferred type](https://istio.io/docs/reference//config/policy-and-telemetry/expression-language/#type-checking) must match the datatype of the field.
type Instance struct {
	// Name of the instance as specified in configuration.
	Name string

	// Variables that are delivered for each log entry.
	Variables map[string]interface{}

	// Timestamp is the time value for the log entry
	Timestamp time.Time

	// Severity indicates the importance of the log entry.
	Severity string

	// Optional. An expression to compute the type of the monitored resource this log entry is being recorded on.
	// If the logging backend supports monitored resources, these fields are used to populate that resource.
	// Otherwise these fields will be ignored by the adapter.
	MonitoredResourceType string

	// Optional. A set of expressions that will form the dimensions of the monitored resource this log entry is being
	// recorded on. If the logging backend supports monitored resources, these fields are used to populate that resource.
	// Otherwise these fields will be ignored by the adapter.
	MonitoredResourceDimensions map[string]interface{}
}

// HandlerBuilder must be implemented by adapters if they want to
// process data associated with the 'logentry' template.
//
// Mixer uses this interface to call into the adapter at configuration time to configure
// it with adapter-specific configuration as well as all template-specific type information.
type HandlerBuilder interface {
	adapter.HandlerBuilder

	// SetLogEntryTypes is invoked by Mixer to pass the template-specific Type information for instances that an adapter
	// may receive at runtime. The type information describes the shape of the instance.
	SetLogEntryTypes(map[string]*Type /*Instance name -> Type*/)
}

// Handler must be implemented by adapter code if it wants to
// process data associated with the 'logentry' template.
//
// Mixer uses this interface to call into the adapter at request time in order to dispatch
// created instances to the adapter. Adapters take the incoming instances and do what they
// need to achieve their primary function.
//
// The name of each instance can be used as a key into the Type map supplied to the adapter
// at configuration time via the method 'SetLogEntryTypes'.
// These Type associated with an instance describes the shape of the instance
type Handler interface {
	adapter.Handler

	// HandleLogEntry is called by Mixer at request time to deliver instances to
	// to an adapter.
	HandleLogEntry(context.Context, []*Instance) error
}
