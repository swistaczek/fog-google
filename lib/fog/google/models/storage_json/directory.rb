require "fog/core/model"
require "fog/google/models/storage_json/files"

module Fog
  module Google
    class StorageJSON
      class Directory < Fog::Model
        identity :key, :aliases => %w(Name name)

        def acl=(new_acl)
          valid_acls = ["private", "public-read", "public-read-write", "authenticated-read"]
          unless valid_acls.include?(new_acl)
            raise ArgumentError.new("acl must be one of [#{valid_acls.join(', ')}]")
          end
          @acl = new_acl
        end

        def destroy
          requires :key
          service.delete_bucket(key)
          true
        rescue Excon::Errors::NotFound
          false
        end

        def files
          @files ||= begin
            Fog::Google::StorageJSON::Files.new(
              :directory => self,
              :service => service
            )
          end
        end

        def public=(new_public)
          if new_public
            @acl = "public-read"
          else
            @acl = "private"
          end
          new_public
        end

        def public_url
          requires :key
          if service.get_bucket_acl(key).body["AccessControlList"].detect { |entry| entry["Scope"]["type"] == "AllUsers" && entry["Permission"] == "READ" }
            if key.to_s =~ /^(?:[a-z]|\d(?!\d{0,2}(?:\.\d{1,3}){3}$))(?:[a-z0-9]|\.(?![\.\-])|\-(?![\.])){1,61}[a-z0-9]$/
              "https://#{key}.storage.googleapis.com"
            else
              "https://storage.googleapis.com/#{key}"
            end
          end
        end

        def save
          requires :key
          # TODO: Write.
        end
      end
    end
  end
end
