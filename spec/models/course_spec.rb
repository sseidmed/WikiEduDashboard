require 'rails_helper'
require 'media_wiki'

describe Course, type: :model do
  it 'should update data for all courses on demand' do
    VCR.use_cassette 'wiki/course_data' do
      course_id = '351'
      raw_ids = { hash: course_id }
      Course.update_all_courses(false, raw_ids)
      Course.update_all_caches

      course = Course.all.first

      expect(course.term).to eq('Summer 2014')
      expect(course.school).to eq('University of Oklahoma')
      expect(course.user_count).to eq(12)
    end
  end

  it 'should perform ad-hoc course updates' do
    VCR.use_cassette 'wiki/course_data' do
      build(:course, id: '351').save

      course = Course.all.first
      course.update
      course.update_cache

      expect(course.term).to eq('Summer 2014')
      expect(course.school).to eq('University of Oklahoma')
      expect(course.user_count).to eq(12)
    end
  end

  it 'should cache revision data for students' do
    build(:user,
          id: 1,
          wiki_id: 'Ragesoss'
    ).save

    build(:course,
          id: 1,
          start: '2015-01-01'.to_date,
          end: '2015-07-01'.to_date,
          title: 'Underwater basket-weaving'
    ).save

    build(:article,
          id: 1,
          title: 'Selfie',
          namespace: 0
    ).save

    build(:revision,
          id: 1,
          user_id: 1,
          article_id: 1,
          date: '2015-03-01'.to_date,
          characters: 9000,
          views: 1234
    ).save

    # Assign the article to the user.
    build(:assignment,
          course_id: 1,
          user_id: 1,
          article_id: 1,
          article_title: 'Selfie'
    ).save

    # Make a course-user and save it.
    build(:courses_user,
                        id: 1,
                        course_id: 1,
                        user_id: 1,
                        assigned_article_title: 'Selfie'
    ).save

    # Make an article-course.
    build(:articles_course,
          id: 1,
          article_id: 1,
          course_id: 1
    ).save

    # Update caches
    ArticlesCourses.update_all_caches
    CoursesUsers.update_all_caches
    Course.update_all_caches

    # Fetch the created CoursesUsers entry
    course = Course.all.first

    expect(course.character_sum).to eq(9000)
    expect(course.view_sum).to eq(1234)
    expect(course.revision_count).to eq(1)
    expect(course.article_count).to eq(1)
  end

  it 'should return a valid course slug for ActiveRecord' do
    course = build(:course,
                   title: 'History Class',
                   slug: 'History_Class'
    )
    expect(course.to_param).to eq('History_Class')
  end

  describe '#url' do
    it 'should return the url of a course page' do
      course = build(:course,
                     slug: 'UW Bothell/Conservation Biology (Winter 2015)'
      )
      url = course.url
      # rubocop:disable Metrics/LineLength
      expect(url).to eq("https://#{Figaro.env.wiki_language}.wikipedia.org/wiki/Education_Program:UW_Bothell/Conservation_Biology_(Winter_2015)")
      # rubocop:enable Metrics/LineLength
    end
  end
end
