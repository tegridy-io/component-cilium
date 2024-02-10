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

local bgpPeeringPolicies = [
  kube._Object('cilium.io/v2alpha1', 'CiliumBGPPeeringPolicy', 'peering-policy-' + name) {
    metadata+: {
      namespace: params.namespace,
    },
    // metadata:
    //  name: 01-bgp-peering-policy
    spec+: params.bgp.peeringPolicies[name],
  }
  for name in std.objectFields(params.bgp.peeringPolicies)
];

local bpgLoadbalancerPools = [
  kube._Object('cilium.io/v2alpha1', 'CiliumLoadBalancerIPPool', name) {
    metadata+: {
      namespace: params.namespace,
    },
    spec+: {
      blocks: params.bgp.loadbalancerPools[name],
    },
  }
  for name in std.objectFields(params.bgp.loadbalancerPools)
];

// Define outputs below
{
  [if params.namespace != 'kube-system' then '00_namespace']: namespace,
  [if params.gateway.enabled then '00_crds_gateway']: crds,
  [if params.bgp.enabled then '20_bgp_peers']: bgpPeeringPolicies,
  [if params.bgp.enabled then '20_bgp_lbpools']: bpgLoadbalancerPools,
}
