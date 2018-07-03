#import "GramTools.h"

#include <fstream>
#include "cword.hpp"

static vector<cword> dict;

@implementation GramTools

+ (void)initialize {
    [GramTools buildDict:3];
}

+ (void)buildDict:(int)level {
    if(level < 1 || level > 5)
        level = 3;
    dict.clear();
    NSString *fp = [[NSBundle mainBundle] pathForResource:[NSString stringWithFormat:@"SL%d", level] ofType:@""];
    ifstream infile(fp.UTF8String);
    string read;
    while(infile >> read)
        dict.push_back(cword(read));
    // i believe SL stands for sorted list, otherwise you'd need:
    // sort(dict.begin(), dict.end());
    infile.close();
}

+ (BOOL)doesSubanagramComplete:(NSString *)sub plain:(NSString *)p gram:(NSString *)g {
    const cword plain = cword(string(p.UTF8String));
    const cword gram = cword(string(g.UTF8String));
    return plain - gram == cword(string(sub.UTF8String));
}

+ (int)cmpWithPlain:(NSString *)p gram:(NSString*)g {
    const cword plain = cword(string(p.UTF8String));
    const cword gram = cword(string(g.UTF8String));
    if(plain == gram)
        return 0;
    if(gram.isSubwordOf(plain))
        return -1;
    return 1;
}

+ (NSDictionary<NSString *, NSNumber *> *)statsWithPlain:(NSString *) p gram:(NSString*)g {
    const cword plain = cword(string(p.UTF8String));
    const cword gram = cword(string(g.UTF8String));
    const cword target = plain - gram;
    NSMutableDictionary<NSString *, NSNumber *> *ret = [NSMutableDictionary new];
    for(int i = 'a'; i <= 'z'; ++i)
        [ret setObject:@(target[i]) forKey:[NSString stringWithFormat:@"%c", i+'A'-'a']];
    return ret;
}

+ (NSArray *)subanagramWithPlain:(NSString *) p gram:(NSString *)g filter:(NSString *)filt use:(NSString *)use {
    const cword plain = cword(string(p.UTF8String));
    const cword gram = cword(string(g.UTF8String));
    const cword target = plain - gram;

    const cword filterCounts = cword(string(filt.UTF8String));
    const cword useCounts = cword(string(use.UTF8String));
    const auto filter = [&filterCounts, &useCounts](const cword &word) -> bool {
        if(!useCounts.isSubwordOf(word))
            return true;
        for(char i = 'a'; i <= 'z'; ++i)
            if(filterCounts[i] && filterCounts[i] <= word[i])
                return true;
        return false;
    };

    const auto subanagrams = subanagram(target, dict);
    NSMutableArray<NSMutableArray *> *ret = [NSMutableArray new];
    for(auto sub: subanagrams) {
        if(filter(sub))
            continue;
        while(ret.count < sub.len)
            [ret addObject:[NSMutableArray new]];
        [ret.lastObject addObject:[NSString stringWithUTF8String:sub.value.c_str()]];
    }
    return ret;
}

vector<cword> exclude(NSString *excludedWordlist) {
    NSArray<NSString *> *excludedWords = [excludedWordlist componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@" ,"]];
    auto filteredDict(dict);
    for(NSString *wordString in excludedWords) {
        string word(wordString.UTF8String);
        auto it = lower_bound(filteredDict.begin(), filteredDict.end(), cword(word));
        if(word == it->value)
            filteredDict.erase(it);
    }
    return filteredDict;
}

+ (NSArray *)anagramWithPlain:(NSString *) p gram:(NSString *)g op:(NSOperation *)op exclude:(NSString *)ex gramLimit:(int)gramLimit timeLimit:(double)timeLimit {
    const cword plain = cword(string(p.UTF8String));
    const cword gram = cword(string(g.UTF8String));
    const cword target = plain - gram;
    const NSDate *date = [NSDate date];
    const auto termCond = [&op, &date, timeLimit]() -> bool {
        return op.cancelled || -date.timeIntervalSinceNow > timeLimit;
    };

    vector<vector<cword>> anagrams;
    if(ex.length != 0) {
        auto filteredDict = exclude(ex);
        anagrams = partanagram(target, filteredDict, gramLimit, termCond);
    }
    else
        anagrams = partanagram(target, dict, gramLimit, termCond);

    vector<pair<float, string> > scoredAnagrams;
    for(auto gram : anagrams) {
        string value = "";
        float score = 0;
        for(auto word : gram) {
            value += word.value + " ";
            score += sqrt(max(0, word.len - 2));
        }
        score /= gram.size();
        scoredAnagrams.push_back(make_pair(score, value));
    }
    sort(scoredAnagrams.begin(), scoredAnagrams.end(), greater<pair<float, string> >());

    NSMutableArray *ret = [NSMutableArray new];
    for(auto gram : scoredAnagrams) {
        id value = [NSString stringWithUTF8String:gram.second.c_str()];
        [ret addObject:value];
        if(ret.count >= gramLimit)
            break;
    }
    return ret;
}

@end
