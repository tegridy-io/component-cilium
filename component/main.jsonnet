// main template for cilium
local kap = import 'lib/kapitan.libjsonnet';
local kube = import 'lib/kube.libjsonnet';
local inv = kap.inventory();
// The hiera parameters for the component
local params = inv.parameters.cilium;

local namespace = kube.Namespace(params.namespace) {
  metadata+: {
    labels+: {
      'app.kubernetes.io/name': params.namespace,
      'pod-security.kubernetes.io/enforce': 'privileged',
    },
  },
};

local crds = std.parseJson(kap.yaml_load_stream('cilium/crds/gateway_api/%s/standard.yaml' % params.gateway.version));

local bgp_peeringpolicy = kube._Object('cilium.io/v2alpha1', 'CiliumBGPPeeringPolicy', 'default') {
  metadata+: {
    namespace: params.namespace,
  },
  spec: {
    nodeSelector: params.bgp.config.nodeSelector,
    virtualRouters: params.bgp.config.virtualRouters,
  },
};

// Define outputs below
{
  [if params.namespace != 'kube-system' then '00_namespace']: namespace,
  [if params.gateway.enabled then '00_crds_gateway']: crds,
  [if params.bgp.enabled then '20_bgp_peeringpolicy']: bgp_peeringpolicy,
}
