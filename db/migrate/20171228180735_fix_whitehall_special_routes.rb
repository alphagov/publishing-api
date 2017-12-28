require_relative "helpers/february29th2016"

class FixWhitehallSpecialRoutes < ActiveRecord::Migration[5.1]
  def up
    data = [
      # /government
      ["4672b1ff-f147-4d49-a5f4-4959588da5a8", "2015-08-10T09:38:52Z"],
      # /courts-tribunals
      ["f990c58c-687a-4baf-b1a0-ec2d02c4d654", "2015-08-10T09:38:52Z"]
    ]
    Helpers::February29th2016.replace_first_published_at(data)
  end
end
