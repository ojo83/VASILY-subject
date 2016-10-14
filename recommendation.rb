#参考
#http://qiita.com/ynakayama/items/ceb3f6408231ea3d230c
#https://github.com/ynakayama/sandbox/blob/master/ruby/machine-learning/recommendation/recommendations.rb
#http://memo.sugyan.com/entry/20081007/1223331850

#############################データの格納#############################
#ユーザデータの格納
def user_data
    udata=Hash.new{|hash,key|hash[key]=Hash.new{0}} #ユーザID，映画のタイトル，点数を格納
    open("u.data"){|f|
        while line=f.gets
            data=line.chomp.split(/\t/)
            userid=data[0].to_i
            itemid=data[1].to_i
            rating=data[2].to_f
            
            udata[userid][itemid]=rating
        end
    }
    return udata
end

#映画データの格納
def movie_data
    tdata=Hash.new(0) #映画ID，タイトルを格納
    gdata=Hash.new(0) #映画ID，ジャンルを格納
    open("u1.item"){|f|
        while line=f.gets
            data=line.chomp.split('|')
            itemid=data[0].to_i
            name=data[1]
            genre=data[3]
            
            tdata[itemid]=name
            gdata[itemid]=genre
        end
    }
    return tdata,gdata
end

############################データ変換###########################
#ジャンルの提示
#1が立っていたら該当するジャンルを配列に格納する
def genre_pickup(genre)
    genre_split=genre.split('')
    genre=Array.new(0)
    
    if genre_split[0]=='1'
        genre << ["unknown"]
    end
    if genre_split[1]=='1'
        genre << ["Action"]
    end
    if genre_split[2]=='1'
        genre << ["Adventure"]
    end
    if genre_split[3]=='1'
        genre << ["Animation"]
    end
    if genre_split[4]=='1'
        genre << ["Children's"]
    end
    if genre_split[5]=='1'
        genre << ["Comedy"]
    end
    if genre_split[6]=='1'
        genre << ["Crime"]
    end
    if genre_split[7]=='1'
        genre << ["Documentary"]
    end
    if genre_split[8]=='1'
        genre << ["Drama"]
    end
    if genre_split[9]=='1'
        genre << ["Fantasy"]
    end
    if genre_split[10]=='1'
        genre << ["Film-Noir"]
    end
    if genre_split[11]=='1'
        genre << ["Horror"]
    end
    if genre_split[12]=='1'
        genre << ["Musical"]
    end
    if genre_split[13]=='1'
        genre << ["Mystery"]
    end
    if genre_split[14]=='1'
        genre << ["Romance"]
    end
    if genre_split[15]=='1'
        genre << ["Sci-Fi"]
    end
    if genre_split[16]=='1'
        genre << ["Thriller"]
    end
    if genre_split[17]=='1'
        genre << ["War"]
    end
    if genre_split[18]=='1'
        genre << ["Western"]
    end
    
    return genre
end

#############################推薦アルゴリズム#################################
#ピアソン相関係数
#r=(ΣXY-((ΣX*ΣY)/N))/√((ΣX^2-(ΣX^2/N))*(ΣY^2-(ΣY^2/N)))
#計算に必要なものΣXY,ΣX,ΣY,ΣX^2,ΣY^2
def pearson(prefs, user1, user2)
    shared_items = prefs[user1].keys & prefs[user2].keys#双方が観たことのある映画を取得
    
    n = shared_items.size
    return 0 if n <= 5 #5つ以上同じ映画を観ている場合のみ類似度を算出する
    
    sum1 = shared_items.inject(0) {|result,rating| #ΣX
        result + prefs[user1][rating]
    }
   
    sum2 = shared_items.inject(0) {|result,rating| #ΣY
        result + prefs[user2][rating]
    }
    sum1_sq = shared_items.inject(0) {|result,rating|#ΣX^2
        result + prefs[user1][rating]**2
    }
    sum2_sq = shared_items.inject(0) {|result,rating|#ΣY^2
        result + prefs[user2][rating]**2
    }
    sum_products = shared_items.inject(0) {|result,rating|#ΣXY
        result + prefs[user1][rating]*prefs[user2][rating]
    }
    
    num = sum_products - (sum1*sum2/n) #ΣXY-((ΣX*ΣY)/N)
    den = Math.sqrt((sum1_sq - sum1**2/n)*(sum2_sq - sum2**2/n))#√(ΣX^2-(ΣX^2/N))*(ΣY^2-(ΣY^2/N))
    return 0 if den == 0
    return num/den #(ΣXY-((ΣX*ΣY)/N))/√((ΣX^2-(ΣX^2/N))*(ΣY^2-(ΣY^2/N)))
end

#類似度トップn位を出す
def top_matches(prefs, user, n)
    scores = Array.new
    prefs.each do |other,val|
        if other != user
            scores << [pearson(prefs,user,other),other] #ピアソン相関係数で類似度を算出する
        end
    end
    scores.sort.reverse[0,n]
end

#類似度が高いユーザーの評点の加重平均を使い推薦する映画を算出する
#各データをxi，重みをwiとしたときの加重平均 (w1*x1+...+wn*xn)/(w1+...wn)
def get_recommendations(prefs, user, gdata, favo)
    totals = Hash.new(0)
    co_sums = Hash.new(0)
    n=10
    
    topn=top_matches(prefs,user,n)#類似度が高いユーザトップn人を算出する

    topn.each do |co,other|#類似度の高いユーザが観た映画のみから推薦する
        prefs[other].each do |itemid, rating|
            if !prefs[user].keys.include?(itemid) #まだ観ていない映画
                favo.each do |genre,count|#ユーザがよく観るジャンルトップ5の映画のみを推薦する
                    if gdata[itemid]==genre
                        totals[itemid] += prefs[other][itemid]*co #加重平均分子
                        co_sums[itemid] += co #加重平均分母
                    end
                end
            end
        end
    end

    rankings = Array.new
    totals.each do |itemid,total|
        rankings << [total/co_sums[itemid], itemid]#加重平均を計算し，映画IDとともに配列に格納する
    end
    rankings.sort.reverse[0,20]#重みが大きいかつユーザがよく観るジャンルの映画(推薦する映画)トップ20を返す
end

#ユーザがよく観ているジャンルトップ5を返す
def favorite_genre(pref, genre)
    genre_count=Hash.new(0)
    pref.each do |itemid,val|
        genre_count[genre[itemid]]+=1
    end
    genre_count.sort_by{|key,val|-val}[0,5]
end

##################################入出力##################################
#ユーザIDの入力
def input
    loop do
        puts "Could you input your user ID(1-943)."
        userid=gets.chomp.to_i
        puts
        return userid if  (userid =~ /^[0-9]+$/)
        return userid if userid<=943
    end
end

#結果出力
def output(movie,tdata,gdata)
    movie.each do |co,itemid|
        tdata[itemid].each do |title|
            print title,', genres: '
            puts genre_pickup(gdata[itemid]).join(',')#推薦した映画のジャンルを提示する
        end
    end
end

#################################main関数##################################
def main
    userid=input#ユーザーID入力
    
    start_time = Time.now #処理時間
    
    udata=user_data #ユーザデータ格納
    tdata,gdata=movie_data #映画データ格納
    
    #ユーザがよく観ている映画のジャンルを5つ返す
    favorite=favorite_genre(udata[userid],gdata)
    
    #ユーザが観ていない映画から加重平均で推薦する映画を算出し，かつユーザがよく観ているジャンルの映画のみ推薦する
    movie=get_recommendations(udata,userid,gdata,favorite)
    
    output(movie,tdata,gdata)#推薦する映画の出力
    
    puts "\ntime #{Time.now-start_time}s"#処理時間出力
end

main


