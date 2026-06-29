# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)

require "context_pack_builder"
require "fileutils"
require "minitest/autorun"
require "stringio"
require "tmpdir"
