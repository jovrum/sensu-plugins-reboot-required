#! /usr/bin/env ruby
# encoding: UTF-8

# check-reboot-required
#
# DESCRIPTION:
# Check if a reboot was required by a package upgrade on a RedHat-based OS.
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
require 'open3'

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
    stdout, status = Open3.capture2('needs-restarting --reboothint')
    ok if status.success?

    packages = stdout.lines
                     .drop(1)
                     .take_while { |line| !line.chomp.empty? }
                     .map { |pkg_desc| pkg_desc.split(' -> ').first.strip }
                     .sort
                     .uniq
                     .reject(&method(:package_ignored?))

    ok if packages.empty?
    warning("reboot required by packages: #{packages.join(', ')}")
  end
end
