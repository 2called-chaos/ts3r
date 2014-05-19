module Heatmon
  module Parser
    module Unix
      module Proc
        # Parses the output of `/proc/mdstat` and provides rubyish access to the results.
        class Mdstat
          include Parser::Support



          # @!group Setup

          # Returns a new parser instance.
          #
          # @param [String] input Mdstat to parse
          # @note You can omit the input and set it with {#input=} before parsing.
          def initialize input = nil
            @input = input
          end

          # Set the input after initialization.
          #
          # @param [String] val Mdstat to parse
          # @raise [RuntimeError] when attempting to change the input after parsing.
          def input= val
            raise RuntimeError, "you cannot change the input data after accessing it's parsed data" if @data
            @input = val
          end

          # @return [String] String which got or is about to get parsed.
          def input
            @input
          end

          # @!endgroup



          # @!group Result API

          # data accessor (lazy parsing)
          #
          # @return [Hash] parsed mdstat
          def data
            @data ||= parse
          end

          # Supported RAID levels by the kernel.
          #
          # @return [Array] List of available RAID levels (:raid0, :raid1, etc.)
          def personalities
            data[:personalities]
          end

          # Unused devices.
          #
          # @return [Array] List of available/unused {Device}s
          def unused_devices
            data[:unused_devices]
          end

          # RAID devices.
          #
          # @return [Array] List of active RAID {Device}s
          def raid_devices
            data[:raid_devices]
          end

          # @!endgroup



        protected



          # @!group Parsing

          # Parses {#input} and returns a hash with the results.
          #
          # @raise [ParseError] [description]
          # @return [Hash] Result hash with :personalities, :unused_devices and :raid_devices
          def parse
            {}.tap do |r|
              error = catch(:parse_error) do
                lines = string_to_lines(@input)
                throw :parse_error, "unknown format" if lines.length <= 2

                # first line: Personalities
                r[:personalities] = _parse_personalities(lines.shift)

                # last line: unused devices
                r[:unused_devices] = _parse_unused_devices(lines.pop)

                # rest: raid devices
                r[:raid_devices] = _parse_raid_devices(lines)

                :success
              end
              raise Error::ParseError, "Failed to parse mdstat#{": #{error}"}" unless error == :success
            end
          end

          # Parses personalities line and returns list of supported RAID levels.
          #
          # @param [String] line Line to parse
          # @return [Array] Array of symbols of supported RAID levels
          def _parse_personalities line
            line  = line.downcase
            row   = _colon_row(line)
            throw :parse_error, "expected 'personalities` but got '#{row.id}`" if row.id != "personalities"
            throw :parse_error, "unexpected 'personalities` format (has #{row.parts.count} parts)" if row.parts.count != 2

            row.items.map{|s| s.gsub(/\[([\w]+)\]/, '\1') }
          end

          # Parses line with unused devices and returns list of {Device}s.
          #
          # @param [String] line Line to parse
          # @return [Array] List of unused {Device}s
          def _parse_unused_devices line
            line = line.downcase
          end

          # Parses lines with active RAID devices and returns list of {Device}s.
          #
          # @param [String] lines Lines to parse
          # @return [Array] List of active RAID {Device}s
          def _parse_raid_devices lines
            binding.pry
          end

          # Helper method to process `identifier: item1 item2` lines.
          #
          # @param [String] str Line to parse
          # @return [OpenStruct] Result with `#id`, `#parts` and `#items`
          def _colon_row str
            OpenStruct.new.tap do |r|
              r.parts = str.split(":")
              r.id    = r.parts.first.strip
              r.items = r.parts[1].split.map(&:strip).reject(&:blank?)
            end
          end

          # @!endgroup



          # Model for RAID devices
          class Device

          end
        end
      end
    end
  end
end

# trait(:ex_0) { cat %q{
#   Personalities : [raid0] [raid1] [raid6] [raid5] [raid4] [raid10]
#   md2 : active raid1 sdb3[1] sda3[0]
#         1462516672 blocks [2/2] [UU]

#   md1 : active raid1 sda2[0] sdb2[1]
#         524224 blocks [2/2] [UU]

#   md0 : active (auto-read-only) raid1 sda1[0] sdb1[1]
#         2096064 blocks [2/2] [UU]

#   unused devices: <none>
# }}

# trait(:ex_1) { cat %q{
#   Personalities : [raid1] [raid6] [raid5] [raid4]
#   md_d0 : active raid5 sde1[0] sdf1[4] sdb1[5] sdd1[2] sdc1[1]
#         1250241792 blocks super 1.2 level 5, 64k chunk, algorithm 2 [5/5] [UUUUU]
#         bitmap: 0/10 pages [0KB], 16384KB chunk

#   unused devices: <none>
# }}
