module OpenID
  class Consumer
    class IdResHandler
      def check_signature
        if @store.nil?
          assoc = nil
        else
          assoc = @store.get_association(server_url, fetch('assoc_handle'))
        end

        if assoc.nil?
          check_auth
        else
          if assoc.expires_in <= 0
            raise ProtocolError, "Association with #{server_url} expired"
          elsif !assoc.check_message_signature(@message)
            Util.log "Bad signature in response from #{server_url}"
          end
        end
      end

      def process_check_auth_response(response)
        is_valid = response.get_arg(OPENID_NS, 'is_valid', 'false')

        invalidate_handle = response.get_arg(OPENID_NS, 'invalidate_handle')
        if !invalidate_handle.nil?
          Util.log("Received 'invalidate_handle' from server #{server_url}")
          if @store.nil?
            Util.log('Unexpectedly got "invalidate_handle" without a store!')
          else
            @store.remove_association(server_url, invalidate_handle)
          end
        end

        if is_valid != 'true'
          Util.log("Server #{server_url} responds that the "\
                                "'check_authentication' call is not valid")
        end
      end
    end
  end
end
