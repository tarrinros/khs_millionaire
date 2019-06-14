class QuestionsController < ApplicationController
  before_action :authenticate_user!

  before_action :authorize_admin!

  # Questions pack load form
  def new
  end

  def create
    level = params[:questions_level].to_i
    q_file = params[:questions_file]

    # http://stackoverflow.com/questions/2521053/how-to-read-a-user-uploaded-file-without-saving-it-to-the-database
    if q_file.respond_to?(:readlines)
      file_lines = q_file.readlines
    elsif q_file.respond_to?(:path)
      file_lines = File.readlines(q_file.path)
    else
      # Redirect to 'new' if cannot read the file
      redirect_to new_questions_path, alert: "Bad file_data: #{q_file.class.name}, #{q_file.inspect}"
      return false
    end

    start_time = Time.now

    # Create questions array and count failed in one big transaction
    failed_count = create_questions_from_lines(file_lines, level)

    # redirect to new with the statistic
    redirect_to new_questions_path,
                notice: "Уровень #{level}, обработано #{file_lines.size}," +
                  " создано #{file_lines.size - failed_count}," +
                  " время #{Time.at((Time.now - start_time).to_i).utc.strftime '%S.%L сек'}"
  end


  private

  def authorize_admin!
    redirect_to root_path unless current_user.is_admin
  end

  # Loading question array into base
  # https://www.coffeepowered.net/2009/01/23/mass-inserting-data-in-rails-without-killing-your-performance/
  def create_questions_from_lines(lines, level)
    failed = 0
    ActiveRecord::Base.transaction do
      lines.each do |line|
        ar = line.split('|')
        q = Question.create(
          level: level,
          text: ar[0].squish,
          answer1: ar[1].squish,
          answer2: ar[2].squish,
          answer3: ar[3].squish,
          answer4: ar[4].squish
        )
        failed += 1 unless q.valid?
      end
    end

    failed
  end
end
