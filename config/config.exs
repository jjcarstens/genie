use Mix.Config

config :nerves, :firmware, rootfs_overlay: "rootfs_overlay"

config :shoehorn,
  init: [:nerves_runtime, :nerves_init_gadget],
  app: Mix.Project.config()[:app]

config :logger, backends: [RingLogger]

##
# SSH access
#
keys = [Path.join([System.user_home!(), ".ssh", "mx.pub"])]
  |> Enum.filter(&File.exists?/1)

config :nerves_firmware_ssh,
  authorized_keys: Enum.map(keys, &File.read!/1)


# Setting the node_name will enable Erlang Distribution.
# Only enable this for prod if you understand the risks.
node_name = if Mix.env() != :prod, do: "genie"

config :nerves_init_gadget,
  ifname: "wlan0",
  address_method: :dhcp,
  mdns_domain: "lamp.local",
  node_name: node_name,
  node_host: :mdns_domain

##
# Setup Networking
passcode = File.read!(".wifi_passcode") |> String.trim

config :nerves_network,
  regulatory_domain: "US"

config :nerves_network, :default,
  wlan0: [
    networks: [
      [ssid: "nunya", psk: "bidness", key_mgmt: :"WPA-PSK"],
      [ssid: "zwei.vier_hurtz", psk: passcode, key_mgmt: :"WPA-PSK"]
    ]
  ],
  eth0: [
    ipv4_address_method: :dhcp
  ]

config :genie, :websocket_url, System.get_env("WEBSOCKET_URL") || "ws://localhost:4000/nerves/websocket"
config :genie, :websocket_token, System.get_env("WEBSOCKET_TOKEN") || "some_token"

# import_config "#{Mix.target()}.exs"
