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

      end
    end
  end
end

