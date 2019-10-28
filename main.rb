require 'fileutils'
require 'date'
require 'rugged'
require 'dotenv'

# 環境変数の読込
Dotenv.load

# ビルダーのソースコードをクローン
Rugged::Repository.clone_at("https://github.com/toshieji/arita2019.git", "repo")

# Aritaのソースコードをクローン
Rugged::Repository.clone_at("https://github.com/marketingnovelgames/Arita.git", "script")

# 最新のビルダーのソースコードを取得
dir = Dir.glob("repo/browser_*")

match = dir.map {|d|
    if d =~ /#{Date.today.to_s.gsub(/-/, '')}/
        d.sub(/repo\/browser_/, '').sub(/_/, '').to_i
    end
}.compact

new_data_path = match.max.to_s

FileUtils.cp_r "./repo/browser_#{new_data_path.insert 8, "_"}/data", "./script/data", {:remove_destination => true}

# GitHubへのCredential
credentials = Rugged::Credentials::UserPassword.new(
  username: ENV["USERNAME"],
  password: ENV["ACCESS_TOKEN"]
)

# 以下、リポジトリのコミット処理
arita_repo = Rugged::Repository.new("./script")

oid = arita_repo.write("This is a blob.", :blob)
index = arita_repo.index
index.read_tree(arita_repo.head.target.tree)
index.add_all()

options = {}
options[:tree] = index.write_tree(arita_repo)

options[:author] = { :email => ENV["GIT_EMAIL"], :name => ENV["GIT_USERNAME"], :time => Time.now }
options[:committer] = { :email => ENV["GIT_EMAIL"], :name => ENV["GIT_USERNAME"], :time => Time.now }
options[:message] ||= "Auto Merge!"
options[:parents] = arita_repo.empty? ? [] : [ arita_repo.head.target ].compact
options[:update_ref] = 'HEAD'

Rugged::Commit.create(arita_repo, options)

arita_repo.push(arita_repo.remotes["origin"], ["refs/heads/master"], credentials: credentials)

# cloneしたソースコードを削除
FileUtils.rm_rf("repo")
FileUtils.rm_rf("script")