#! /usr/bin/env ruby
# encoding: UTF-8

#
# check-reboot-required
#
# DESCRIPTION:
# Check if a reboot was required by a package upgrade on a Debian-based OS.
#
# OUTPUT:
#   plain text
#
# PLATFORMS:
#   Linux
#
# DEPENDENCIES:
#   gem: sensu-plugin
#
# USAGE:
#
# NOTES:
#

require 'sensu-plugin/check/cli'

class CheckRebootRequired < Sensu::Plugin::Check::CLI
  option :ignore_packages,
         short: '-i',
         long: '--ignore-packages pkg1[,pkg2,...,pkgN]',
         description: 'Packages requesting reboot to ignore',
         default: ''

  def package_ignored?(pkg)
    @ignored_package_patterns ||= config[:ignore_packages].split(',')
    @ignored_package_patterns.any? { |pattern| File.fnmatch(pattern, pkg) }
  end

  def run
    if File.file?('/var/run/reboot-required')
      reason = File.read('/var/run/reboot-required').chomp
      reason = 'reboot required' if reason.empty?

      pkglist_path = '/var/run/reboot-required.pkgs'
      if File.file?(pkglist_path)
        packages = File.readlines(pkglist_path)
                       .map(&:chomp)
                       .sort
                       .uniq
                       .reject(&method(:package_ignored?))

        if packages.empty?
          ok # Reboot required only by ignored packages
        else
          warning("reboot required by packages: #{packages.join(', ')}")
        end
      else
        warning(reason) # Reboot required by unknown packages
      end
    end
    ok
  end
end
