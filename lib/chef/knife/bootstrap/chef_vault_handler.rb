#
# Author:: Lamont Granquist (<lamont@chef.io>)
# Copyright:: Copyright (c) 2015 Opscode, Inc.
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require 'chef/node'
require 'chef/rest'
require 'chef/api_client/registration'
require 'chef/api_client'

class Chef
  class Knife
    class Bootstrap < Knife
      class ChefVaultHandler

        attr_accessor :knife_config
        attr_accessor :chef_config
        attr_accessor :ui

        def initialize(knife_config: {}, chef_config: {}, ui: nil)
          @knife_config = knife_config
          @chef_config  = chef_config
          @ui           = ui
        end

        def run
          return unless vault_list || vault_file

          ui.info("Updating Chef Vault, waiting for client to be searchable..") while wait_for_client

          update_vault_list
        end

        def update_vault_list

          vault_json.each do |vault, item|
            if item.is_a?(Array)
              item.each do |i|
                update_vault(vault, i)
              end
            else
              update_vault(vault, item)
            end
          end
        end

        private

        def node_name
          knife_config[:chef_node_name]
        end

        def vault_list
          knife_config[:vault_list]
        end

        def vault_file
          knife_config[:vault_file]
        end

        def vault_json
          @vault_json ||=
            begin
              json = vault_list ? vault_list : File.read(vault_file)
              Chef::JSONCompat.from_json(json)
            end
        end

        def update_vault(vault, item)
          vault_item = ChefVault::Item.load(vault, item)
          vault_item.clients("name:#{node_name}")
          vault_item.save
        end

        def wait_for_client
          sleep 1
          !Chef::Search::Query.new.search(:client, "name:#{node_name}")[0]
        end
      end
    end
  end
end

