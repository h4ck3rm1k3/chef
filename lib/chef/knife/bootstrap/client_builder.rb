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
require 'tmpdir'

class Chef
  class Knife
    class Bootstrap < Knife
      class ClientBuilder

        attr_accessor :knife_config
        attr_accessor :chef_config
        attr_accessor :ui

        def initialize(knife_config: {}, chef_config: {}, ui: nil)
          @knife_config = knife_config
          @chef_config  = chef_config
          @ui           = ui
        end

        def run
          sanity_check

          ui.info("Creating new client for #{node_name}")

          create_client!

          ui.info("Creating new node for #{node_name}")

          create_node!
        end

        def client_path
          @client_path ||=
            begin
              # use an ivar to hold onto the reference so it doesn't get GC'd
              @tmpdir = Dir.mktmpdir
              File.join(@tmpdir, "#{node_name}.pem")
            end
        end

        private

        def node_name
          knife_config[:chef_node_name]
        end

        def environment
          knife_config[:environment]
        end

        def run_list
          knife_config[:run_list]
        end

        def first_boot_attributes
          knife_config[:first_boot_attributes]
        end

        def chef_server_url
          chef_config[:chef_server_url]
        end

        def normalized_run_list
          case run_list
          when nil
            []
          when String
            run_list.split(/\s*,\s*/)
          when Array
            run_list
          end
        end

        def create_client!
          Chef::ApiClient::Registration.new(node_name, client_path, http_api: rest).run
        end

        def create_node!
          node.save
        end

        def node
          @node ||=
            begin
              node = Chef::Node.new(chef_server_rest: client_rest)
              node.name(node_name)
              node.run_list(normalized_run_list)
              node.normal_attrs = first_boot_attributes if first_boot_attributes
              node.environment(environment) if environment
              node
            end
        end

        def sanity_check
          if resource_exists?("nodes/#{node_name}")
            ui.confirm("Node #{node_name} exists, overwrite it")
            # Must delete it as the client created later will not have perms to write it
            rest.delete("nodes/#{node_name}")
          end
          if resource_exists?("clients/#{node_name}")
            ui.confirm("Client #{node_name} exists, overwrite it")
            rest.delete("clients/#{node_name}")
          end
        end

        def resource_exists?(relative_path)
          rest.get_rest(relative_path)
          true
        rescue Net::HTTPServerException => e
          raise unless e.response.code == "404"
          false
        end

        def client_exists?
          return @client_exists unless @client_exists.nil?
          @client_exists =
            begin
              rest.get_rest("clients/#{node_name}")
              true
            rescue Net::HTTPServerException => e
              raise unless e.response.code == "404"
              false
            end
        end

        # this is the REST client using the client's credentials instead of the user's
        def client_rest
          @client_rest ||= Chef::REST.new(chef_server_url, node_name, client_path)
        end

        # this uses the users's credentials
        def rest
          @rest ||= Chef::REST.new(chef_server_url)
        end
      end
    end
  end
end
