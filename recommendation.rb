#参考
#http://qiita.com/ynakayama/items/ceb3f6408231ea3d230c
#https://github.com/ynakayama/sandbox/blob/master/ruby/machine-learning/recommendation/recommendations.rb
require 'rubygems'
require 'awesome_print'

#ユーザデータの格納
def user_data
    udata=Hash.new{|hash,key|hash[key]=Hash.new{0}}
    open("u.data"){|f|
        while line=f.gets
            data=line.chomp.split(/\t/)
            userid=data[0]
            itemid=data[1].to_i
            rating=data[2].to_f
            udata[userid][itemid]=rating
        end
    }
    return udata
end

#映画データの格納
def movie_data
    mdata=Hash.new{|hash,key|hash[key]=Hash.new{0}}
    gdata=Hash.new(0)
    open("u1.item"){|f|
        while line=f.gets
            data=line.chomp.split('|')
            itemid=data[0].to_i
            name=data[1]
            url=data[2]
            genre=data[3]#.to_i(2)
            mdata[itemid][name]=genre
            gdata[itemid]=genre
        end
    }
    return mdata,gdata
end

#ポアソン相関係数
def sim_pearson(prefs, user1, user2)
    shared_items_a = prefs[user1].keys & prefs[user2].keys
    
    n = shared_items_a.size
    return 0 if n <= 5 #5つ以上同じ映画を見ている場合のみ類似度を計算する
    
    sum1 = shared_items_a.inject(0) {|result,si|
        result + prefs[user1][si]
    }
    sum2 = shared_items_a.inject(0) {|result,si|
        result + prefs[user2][si]
    }
    sum1_sq = shared_items_a.inject(0) {|result,si|
        result + prefs[user1][si]**2
    }
    sum2_sq = shared_items_a.inject(0) {|result,si|
        result + prefs[user2][si]**2
    }
    sum_products = shared_items_a.inject(0) {|result,si|
        result + prefs[user1][si]*prefs[user2][si]
    }
    
    num = sum_products - (sum1*sum2/n)
    den = Math.sqrt((sum1_sq - sum1**2/n)*(sum2_sq - sum2**2/n))
    return 0 if den == 0
    return num/den
end

#類似度トップn位を出す
#def top_matches(prefs, user, n, similarity=:sim_pearson)
def top_matches(prefs, user, n)
    scores = Array.new
    prefs.each do |key,value|
        if key != user
            #scores << [__send__(similarity,prefs,user,key),key]
            scores << [sim_pearson(prefs,user,key),key] #ポアソン相関係数
        end
    end
    scores.sort.reverse[0,n]
end

#ユーザがよく観ているジャンルトップ5を返す
def favorite_genre(pref, genre)
    genre_count=Hash.new(0)
    pref.each do |id,val|
        genre_count[genre[id]]+=1
    end
    genre_count.sort_by{|key,val|-val}[0,5]
end

# user 以外の全ユーザーの評点の重み付き平均を使い user への推薦を算出する
#def get_recommendations(prefs, user, similarity=:sim_pearson)
def get_recommendations(prefs, user, genre,favo)
    totals_h = Hash.new(0)
    sim_sums_h = Hash.new(0)
    n=10
    
    topn=top_matches(prefs,user,n)
    
    prefs.each do |other,val|
        next if other == user # 自分自身とは比較しない
        sim = sim_pearson(prefs,user,other)
        #sim = __send__(similarity,prefs,user,other)
        next if sim <= topn[n-1][0] # 類似度がトップn位以下のユーザは無視
        prefs[other].each do |item, val|
            # まだ観ていない映画を出す
            if !prefs[user].keys.include?(item) #|| prefs[user][item] == 0
                favo.each do |item2,val2|
                    if genre[item]==item2
                        totals_h[item] += prefs[other][item]*sim
                        sim_sums_h[item] += sim
                    end
                end
                #totals_h[item] = genre[item]
            end
        end
    end
    rankings = Array.new
    totals_h.each do |item,total|
        rankings << [total/sim_sums_h[item], item]
    end
    rankings.sort.reverse[0,20]
end

#ジャンルの提示
def genre_pickup(genre)
    genre_split=genre.split('')
    genre=Array.new(0)
    if genre_split[0]=='1'
        genre.push("unknown")
    end
    if genre_split[1]=='1'
        genre.push("Action")
    end
    if genre_split[2]=='1'
        genre.push("Adventure")
    end
    if genre_split[3]=='1'
        genre.push("Animation")
    end
    if genre_split[4]=='1'
        genre.push("Children's")
    end
    if genre_split[5]=='1'
        genre.push("Comedy")
    end
    if genre_split[6]=='1'
        genre.push("Crime")
    end
    if genre_split[7]=='1'
        genre.push("Documentary")
    end
    if genre_split[8]=='1'
        genre.push("Drama")
    end
    if genre_split[9]=='1'
        genre.push("Fantasy")
    end
    if genre_split[10]=='1'
        genre.push("Film-Noir")
    end
    if genre_split[11]=='1'
        genre.push("Horror")
    end
    if genre_split[12]=='1'
        genre.push("Musical")
    end
    if genre_split[13]=='1'
        genre.push("Mystery")
    end
    if genre_split[14]=='1'
        genre.push("Romance")
    end
    if genre_split[15]=='1'
        genre.push("Sci-Fi")
    end
    if genre_split[16]=='1'
        genre.push("Thriller")
    end
    if genre_split[17]=='1'
        genre.push("War")
    end
    if genre_split[18]=='1'
        genre.push("Western")
    end
    #puts genre
    return genre
end

def input
    loop do
        puts "Could you input your user ID."
        userid=$stdin.gets.chomp
        return userid if  (userid =~ /^[0-9]+$/)# || userid>943)
        #if userid>943
    end
end

def output(movie,mdata)
    movie.each do |sim,itemid|
        mdata[itemid].each do |title,genre|
            print title,', genres: '
            puts genre_pickup(genre).join(',')
        end
    end
end

def main
    userid=input
    #userid='2'
    
    start_time = Time.now #処理時間
    
    udata=user_data
    mdata,gdata=movie_data
    
    favorite=favorite_genre(udata[userid],gdata)
    movie=get_recommendations(udata,userid,gdata,favorite)
    
    output(movie,mdata)
    
    p "time #{Time.now-start_time}s"#処理時間出力
end

main


